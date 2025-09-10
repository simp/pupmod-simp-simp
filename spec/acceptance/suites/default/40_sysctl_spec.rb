require 'spec_helper_acceptance'

test_name 'simp::sysctl class'

describe 'simp::sysctl class' do
  let(:manifest) do
    <<-EOS
      include 'simp::sysctl'
    EOS
  end

  hosts.each do |host|
    context 'default parameters' do
      it 'applies sysctl with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end

    context 'sysctl with enable ipv6 = true' do
      let(:hieradata) do
        YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
          {
            'simp::sysctl::ipv6' => true,
          },
        )
      end

      it 'set hieradata' do
        set_hieradata_on(host, hieradata)
      end

      it 'set ipv6 = true' do
        on(host, 'sysctl net.ipv6.conf.all.disable_ipv6=0')
      end

      it 'applies simp::sysctl with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end

    context 'should disable ipv6 again' do
      let(:hieradata) do
        YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
          {
            'simp::sysctl::ipv6' => false,
          },
        )
      end

      it 'set hieradata' do
        set_hieradata_on(host, hieradata)
      end

      it 'applies simp::sysctl with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'sysctl should disable ipv6' do
        result = on(host, 'sysctl -n net.ipv6.conf.all.disable_ipv6')
        expect(result.output.strip).to eq('1')
      end
    end
  end
end
