require 'spec_helper_acceptance'

test_name 'simp::kernel_param class'

describe 'simp::kernel_param class' do
  let(:manifest) {
    <<-EOS
      include 'simp::kernel_param'
    EOS
  }

  hosts.each do |host|
    context 'default parameters' do
      it 'should kernel_param  with no errors' do
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
        cmdline = on(host, 'cat /proc/cmdline')
        result = on(host, '[[ -f /sys/kernel/debug/x86/ibrs_enable ]]', :accept_all_exit_codes => true)
        if result.exit_code == 0
          expect(cmdline.stdout).to match(%r(spectre_v2=retpoline,ibrs_user))
        else
          expect(cmdline.stdout).to_not match(%r(spectre_v2))
        end
        result2 = on(host, '[[ -f /sys/kernel/debug/x86/pti_enable ]]', :accept_all_exit_codes => true)
        if result2.exit_code == 0
          expect(cmdline.stdout).to_not match(%r( nopti ))
          expect(cmdline.stdout).to match(%r( kpti ))
        else
          expect(cmdline.stdout).to_not match(%r( nopti ))
          expect(cmdline.stdout).to_not match(%r( kpti ))
        end
      end

    end
  end
end
