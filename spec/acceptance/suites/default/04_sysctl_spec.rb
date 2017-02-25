require 'spec_helper_acceptance'

test_name 'simp::sysctl class'

describe 'simp::sysctl class' do
  let(:disable_ipv6_hieradata) {{
    'simp::sysctl::ipv6' => false
  }}
  let(:enable_ipv6_hieradata) {{
    'simp::sysctl::ipv6' => true
  }}

  let(:manifest) {
    <<-EOS
      include 'simp::sysctl'
    EOS
  }

  hosts.each do |host|
    context 'default parameters' do

      it 'should apply sysctl with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

    end

    context 'sysctl with enable ipv6 = true' do

      it 'set hieradata' do
        set_hieradata_on(host, enable_ipv6_hieradata)
      end

      it 'set ipv6 = true' do
        on(host, "sysctl net.ipv6.conf.all.disable_ipv6=0")
      end

      it 'should apply simp::sysctl with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end

    context 'should disable ipv6 again' do

      it 'set hieradata' do
        set_hieradata_on(host, disable_ipv6_hieradata)
      end

      it 'should apply simp::sysctl with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'sysctl should disable ipv6' do
        result = on(host,"sysctl -n net.ipv6.conf.all.disable_ipv6")
        expect(result.output.strip).to eq('1')
      end
    end

  end
end
