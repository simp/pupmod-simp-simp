require 'spec_helper_acceptance'

test_name 'simp::base_apps and simp::base_services class'

describe 'simp::mcollective class' do
  before(:context) do
    hosts.each do |host|
      interfaces = fact_on(host, 'interfaces').strip.split(',')
      interfaces.delete_if do |x|
        x =~ /^lo/
      end

      interfaces.each do |iface|
        if fact_on(host, "ipaddress_#{iface}").strip.empty?
          on(host, "ifup #{iface}", :accept_all_exit_codes => true)
        end
      end
    end
  end

  let(:hieradata) {
    <<-EOS
---
simp_options::firewall: true
simp_options::trusted_nets:
  - 'ALL'
    EOS
  }

  let(:manifest) {
    <<-EOS
include 'simp::base_apps'
include 'simp::base_services'
    EOS
  }

  context 'default parameters' do
    hosts.each do |node|
      it "should prepare #{host}" do
        # Set up base modules and hieradata
        set_hieradata_on( node, hieradata )

        # the portreserve service will fail unless something is configured
        on( node, 'mkdir -p /etc/portreserve')
        on( node, 'echo rndc/tcp > /etc/portreserve/named')
      end

      it 'should apply with no errors' do
        apply_manifest_on( node, manifest, :catch_failures => true )
      end

      it 'should be idempotent' do
        apply_manifest_on( node, manifest, :catch_changes  => true )
      end

    end
  end
end
