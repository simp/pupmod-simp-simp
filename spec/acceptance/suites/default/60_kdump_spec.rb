require 'spec_helper_acceptance'

test_name 'simp::kdump class'

describe 'simp::kdump class' do
  let(:manifest) {
    <<-EOS
      include 'simp::kdump'
    EOS
  }

  # Setting to enable and set crashkernel value because if the system
  # has < 1G of memory crashkernel=auto will not allocate any memory and
  # it will remove it from the boot params.
  let(:manifest2) {
    <<-EOS
      class {'simp::kdump':
        enabled => true,
        crashkernel => '128M',
      }
    EOS
  }

  hosts.each do |host|
    context 'default parameters' do
      it 'should apply kdump with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should reboot and  remove kernel param' do
        host.reboot
        result = on(host, %(cat /proc/cmdline)).stdout
        expect(result).to_not match(/crashkernel/)
        expect(check_for_package(host, 'kexec-tools')).to be false
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

    end

    context 'with enabled = true' do
      it 'should apply manifest2' do
        result = apply_manifest_on(host, manifest2, :catch_failures => true)
        expect(result.output).to include('kdump_reboot => The status of the crashkernel kernel parameter (used for kdump) has changed.')
      end

      it 'should reboot and set kernel param' do
        host.reboot
        result = on(host, %(cat /proc/cmdline)).stdout
        expect(result).to match(/crashkernel=128M/)
        expect(check_for_package(host, 'kexec-tools')).to be true
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest2, :catch_changes => true)
      end
    end

    context 'with enabled = true and crashkernel = auto and memory fact < 1G' do

      it 'should apply manifest2' do
        result = apply_manifest_on(host, manifest2, :catch_failures => true)
        expect(result.output).to include('kdump_reboot => The status of the crashkernel kernel parameter (used for kdump) has changed.')
      end

      it 'should reboot and set kernel param' do
        host.reboot
        result = on(host, %(cat /proc/cmdline)).stdout
        expect(result).to match(/crashkernel=128M/)
        expect(check_for_package(host, 'kexec-tools')).to be true
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest2, :catch_changes => true)
  end
end
