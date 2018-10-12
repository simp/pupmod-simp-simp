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
      it 'should apply sysctl and kernel_param  with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      host.reboot

      it 'should not have spectre boot params' do
        result = on(host, 'cat /proc/cmdline')
        expect(result.stdout).to_not match(%r(spectre_v2))
        expect(result.stdout).to_not match(%r( nopti ))
        expect(result.stdout).to_not match(%r( kpti ))
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

    context 'should apply spectre boot settings' do
      it 'set hieradata' do
        yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
        default_yaml = yaml.merge(
          'simp::kernel_param::spectre_v2' => 'retpoline,ibrs_user',
          'simp::kernel_param::pti' => true
        ).to_yaml

        create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
      end

      it 'should apply simp::sysctl with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end
      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should add settings to command line' do
        host.reboot
        result = on(host, '[[ -f /sys/kernel/debug/x86/ibrs_enable ]]')
        if result.exit_code == 0
          expect(result.stdout).to match(%r(spectre_v2=retpoline,ibrs_user))
        else
          expect(result.stdout).to_not match(%r(spectre_v2))
        end
        result2 = on(host, '[[ -f /sys/kernel/debug/x86/pti_enable ]]')
        if result2.exit_code == 0
          expect(result.stdout).to_not match(%r( nopti ))
          expect(result.stdout).to match(%r( kpti ))
        else
          expect(result.stdout).to_not match(%r( nopti ))
          expect(result.stdout).to_not match(%r( kpti ))
        end
      end

    end
  end
end
