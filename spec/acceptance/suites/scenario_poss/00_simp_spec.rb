require 'spec_helper_acceptance'

test_name 'simp "poss" scenario'

describe 'simp "poss" scenario' do
  let(:manifest) do
    <<-EOS
      # This would be in site.pp, or an ENC or classifier
      include 'simp_options'
      include 'simp'
    EOS
  end

  let(:hieradata) do
    <<~EOF
      # Mandatory settings
      simp_options::puppet::server: #{host_fqdn}
      simp_options::puppet::ca: #{host_fqdn}

      # Settings required for acceptance test
      simp::scenario: poss
    EOF
  end

  hosts.each do |host|
    let(:host_fqdn) { fact_on(host, 'fqdn') }
    let(:ssh_authorized_key) do
      on(host, 'cat ~/.ssh/authorized_keys').stdout.strip.lines.first.split(%r{\s+})[1]
    end

    it 'sets up simp_options through hiera' do
      set_hieradata_on(host, hieradata)
    end

    # These boxes have no root password by default...
    it 'sets the root password' do
      on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
      on(host, 'echo "root:password" | chpasswd --crypt-method SHA256')
    end

    it 'runs puppet' do
      apply_manifest_on(host, manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest_on(host, manifest, catch_changes: true)
    end
  end
end
