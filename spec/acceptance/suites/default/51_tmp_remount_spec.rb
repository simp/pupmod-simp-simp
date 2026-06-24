require 'spec_helper_acceptance'

test_name 'tmp.mount change while busy'

# Regression test for https://github.com/simp/pupmod-simp-simp/issues/372
#
# When the tmp.mount systemd unit is managed, changing the unit file content
# used to notify Service[tmp.mount], which issued a `systemctl restart
# tmp.mount`. For a .mount unit a restart unmounts and remounts /tmp, and the
# unmount fails with `target is busy` whenever a process (including Puppet
# itself) holds an open file under /tmp, aborting the run.
# simp::mountpoints::tmp now sets `service_restart => false` so a unit file
# change is written and daemon-reloaded without restarting (unmounting) /tmp;
# the new options take effect on the next boot.
#
# Note: because the running mount is never restarted, the options are NOT
# applied to the live /tmp during the run (regardless of whether /tmp is
# already tmpfs or a real partition), so this test does not assert the live
# mount type/options -- only that the run succeeds and the change is recorded.
describe 'simp::mountpoints::tmp tmp.mount change' do
  # An open write fd against this file makes /tmp busy so a real unmount would
  # fail with EBUSY, reproducing the issue #372 precondition.
  let(:lock_file) { '/tmp/.busy_372.lock' }
  let(:pid_file)  { '/tmp/.busy_372.pid' }

  let(:holder_script) do
    <<~SH
      #!/bin/bash
      exec 9>#{lock_file}
      echo $BASHPID > #{pid_file}
      exec sleep 600
    SH
  end

  # Manage the tmp.mount unit without noexec...
  let(:initial_manifest) do
    <<~EOS
      class { 'simp::mountpoints::tmp':
        tmp_service => true,
        tmp_opts    => ['nodev', 'nosuid'],
      }
    EOS
  end

  # ...then add noexec, which changes the unit file content. This must not
  # restart (unmount) /tmp while it is busy.
  let(:changed_manifest) do
    <<~EOS
      class { 'simp::mountpoints::tmp':
        tmp_service => true,
        tmp_opts    => ['noexec', 'nodev', 'nosuid'],
      }
    EOS
  end

  hosts.each do |host|
    systemd = on(host, 'command -v systemctl', accept_all_exit_codes: true).exit_code.zero?

    context "on #{host}" do
      unless systemd
        it 'is skipped on non-systemd hosts' do
          skip 'tmp.mount is only managed on systemd systems'
        end
        next
      end

      it 'manages the tmp.mount unit without failing' do
        apply_manifest_on(host, initial_manifest, catch_failures: true)
        apply_manifest_on(host, initial_manifest, catch_changes: true)

        # The unit is enabled/active; the live mount options are intentionally
        # not applied here (they wait for a reboot), so we do not assert them.
        expect(on(host, 'systemctl is-active tmp.mount').output.strip).to eq('active')
      end

      it 'holds /tmp busy with an open file descriptor' do
        create_remote_file(host, '/root/busy_372_holder.sh', holder_script)
        on(host, 'chmod +x /root/busy_372_holder.sh')
        on(host, 'nohup setsid /root/busy_372_holder.sh </dev/null >/dev/null 2>&1 &')

        # Give the holder a moment to write its pid and open the fd
        on(host, "for i in $(seq 1 10); do [ -s #{pid_file} ] && break; sleep 1; done")

        pid = on(host, "cat #{pid_file}").output.strip
        expect(pid).to match(%r{^\d+$})

        # Confirm the mount is genuinely busy (a plain umount would fail)
        on(host, 'umount /tmp', accept_all_exit_codes: true).tap do |result|
          expect(result.exit_code).not_to eq(0)
        end
      end

      it 'applies the unit file change without failing while /tmp is busy' do
        # With the pre-fix restart-as-unmount behavior, this run would abort
        # with "Systemd restart for tmp.mount failed!".
        apply_manifest_on(host, changed_manifest, catch_failures: true)
      end

      it 'leaves the busy process running (i.e. did not unmount /tmp)' do
        pid = on(host, "cat #{pid_file}").output.strip
        expect(on(host, "kill -0 #{pid}", accept_all_exit_codes: true).exit_code).to eq(0)
      end

      it 'records the new options in the unit file (applied on next boot)' do
        expect(on(host, 'cat /etc/systemd/system/tmp.mount').output).to match(%r{^Options=.*\bnoexec\b})
      end

      it 'registers a reboot notification for tmp.mount' do
        vardir = on(host, 'puppet config print vardir').output.strip
        notifications = on(host, "cat #{vardir}/reboot_notifications.json").output
        expect(notifications).to include('tmp.mount')
      end

      it 'is idempotent after the change' do
        apply_manifest_on(host, changed_manifest, catch_changes: true)
      end

      it 'cleans up the busy holder' do
        pid = on(host, "cat #{pid_file}", accept_all_exit_codes: true).output.strip
        on(host, "kill #{pid}", accept_all_exit_codes: true) unless pid.empty?
        on(host, "rm -f #{lock_file} #{pid_file} /root/busy_372_holder.sh")
      end
    end
  end
end
