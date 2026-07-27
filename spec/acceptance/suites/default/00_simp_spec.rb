require 'spec_helper_acceptance'

test_name 'simp'

describe 'simp class' do
  let(:manifest) do
    <<-EOS
      # This would be in site.pp, or an ENC or classifier
      include 'simp_options'
      include 'simp'
    EOS
  end

  hosts.each do |host|
    context "on #{host}" do
      let(:hieradata) do
        YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__))
      end

      it 'sets up hiera' do
        set_hieradata_on(host, hieradata)
      end

      # These boxes have no root password by default...
      it 'sets the root password' do
        on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
        on(host, 'echo "root:password" | chpasswd --crypt-method SHA256')
      end

      it 'bootstraps in a few runs' do
        apply_manifest_on(host, manifest, accept_all_exit_codes: true)
        apply_manifest_on(host, manifest, accept_all_exit_codes: true)
        host.reboot
        sleep(20)
        apply_manifest_on(host, manifest, catch_failures: true)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        # pam sets pam_tty_audit to 'required' only once the simplib__auditd
        # fact reports auditd is enforcing. This is deliberate: it avoids
        # switching pam_tty_audit to 'required' before the kernel audit
        # subsystem is active, which could otherwise lock users out. Because
        # that fact transitions from false to true as this same catalog
        # enables auditd, the sudo and *-auth PAM files legitimately change
        # once more on the first run after the transition. The timing of that
        # transition varies by platform (it can land later on EL8), so
        # converge over a few runs before requiring a no-op run rather than
        # assuming a fixed bootstrap length.
        converged = false
        5.times do
          # catch_failures runs with --detailed-exitcodes and permits changes
          # (exit 2) but still fails on errors (exit 4/6); exit 0 == no changes
          result = apply_manifest_on(host, manifest, catch_failures: true)
          if result.exit_code.zero?
            converged = true
            break
          end
        end
        expect(converged).to eq(true)
      end
    end
  end
end
