require 'spec_helper_acceptance'

test_name 'simp::base_apps class'

describe 'simp::base_apps class' do
  let(:hieradata) do
    <<~EOS
      ---
      simp_options::firewall: true
      simp_options::trusted_nets:
        - 'ALL'
    EOS
  end

  let(:manifest) do
    <<~EOS
      include 'simp::base_apps'
    EOS
  end

  context 'default parameters' do
    hosts.each do |host|
      it "prepares #{host}" do
        # Set up base modules and hieradata
        set_hieradata_on(host, hieradata)
      end

      it 'applies with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end
  end
end
