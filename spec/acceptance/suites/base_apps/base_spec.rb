require 'spec_helper_acceptance'

test_name 'simp::base_apps and simp::base_services class'

describe 'simp::base_apps class' do
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
