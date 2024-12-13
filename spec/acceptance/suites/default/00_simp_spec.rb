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
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end
  end
end
