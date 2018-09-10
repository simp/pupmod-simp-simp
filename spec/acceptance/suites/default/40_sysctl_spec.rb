require 'spec_helper_acceptance'

test_name 'simp::sysctl class'

describe 'simp::sysctl class' do
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
        yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
        default_yaml = yaml.merge(
          'simp::sysctl::ipv6' => true,
        ).to_yaml

        create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
      end

      it 'set ipv6 = true' do
        on(host, 'sysctl net.ipv6.conf.all.disable_ipv6=0')
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
        yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
        default_yaml = yaml.merge(
          'simp::sysctl::ipv6' => false,
        ).to_yaml

        create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
      end

      it 'should apply simp::sysctl with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'sysctl should disable ipv6' do
        result = on(host, 'sysctl -n net.ipv6.conf.all.disable_ipv6')
        expect(result.output.strip).to eq('1')
      end
    end

  end
end
