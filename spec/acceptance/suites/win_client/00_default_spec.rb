require 'spec_helper_acceptance'

test_name 'Windows Node'

describe 'windows node' do
  let(:manifest) do
    <<-EOS
      # This would be in site.pp, or an ENC or classifier
      include 'simp'
    EOS
  end

  let(:hieradata) do
    {
      'simp_options::puppet::server' => host_fqdn,
      'simp_options::puppet::ca'     => host_fqdn,
      'simp::classes'                => ['simp_options'],
    }
  end

  # A Linux host has to be in the nodeset for the setup code
  hosts_with_role(hosts, 'windows').each do |host|
    let(:host_fqdn) { fact_on(host, 'fqdn') }

    it 'applies the test manifest' do
      set_hieradata_on(host, hieradata)
      apply_manifest_on(host, manifest, catch_failures: true)
    end

    it 'may require a reboot' do
      host.reboot
      apply_manifest_on(host, manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest_on(host, manifest, catch_changes: true)
    end
  end
end
