require 'spec_helper_acceptance'

test_name 'tmp.mount remount while busy'

# Regression test for https://github.com/simp/pupmod-simp-simp/issues/372
#
# When /tmp is a tmpfs managed by the tmp.mount systemd unit, changing the
# unit file content used to notify Service[tmp.mount], which issued a
# `systemctl restart tmp.mount`. For a .mount unit a restart unmounts and
# remounts /tmp, and the unmount fails with `target is busy` whenever a
# process (including Puppet itself) holds an open file under /tmp, aborting
# the run. simp::mountpoints::tmp now overrides the restart command with an
# in-place `mount -o remount`, which applies the new options without
# unmounting.
describe 'simp::mountpoints::tmp tmp.mount remount' do
  # The lock file lives on the tmpfs /tmp; an open write fd against it makes
  # the mount busy so a real unmount would fail with EBUSY.
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

  # Establish a tmpfs /tmp without noexec...
  let(:initial_manifest) do
    <<~EOS
      class { 'simp::mountpoints::tmp':
        tmp_service => true,
        tmp_opts    => ['nodev', 'nosuid'],
      }
    EOS
  end

  # ...then add noexec, which changes the unit file content and triggers the
  # refresh (remount) while /tmp is busy.
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

      it 'mounts /tmp as a tmpfs via tmp.mount' do
        apply_manifest_on(host, initial_manifest, catch_failures: true)
        apply_manifest_on(host, initial_manifest, catch_changes: true)

        expect(on(host, 'systemctl is-active tmp.mount').output.strip).to eq('active')
        expect(on(host, "mount | grep ' /tmp '").output).to match(%r{\btmpfs\b})
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

      it 'applied the new options live via remount' do
        expect(on(host, "mount | grep ' /tmp '").output).to match(%r{\bnoexec\b})
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
