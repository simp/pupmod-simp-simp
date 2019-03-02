require 'spec_helper_acceptance'

test_name 'simp::kdump class'

describe 'simp::kdump class' do
  let(:manifest) {
    <<-EOS
      include 'simp::kdump'
    EOS
  }

  let(:manifest2) {
    <<-EOS
      class {'simp::kdump':
        enabled => true,
      }
    EOS
  }

  hosts.each do |host|
    context 'default parameters' do
      it 'should apply kdump with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should reboot and  remove kernel param' do
        host.reboot
        result = on(host, %(cat /proc/cmdline)).stdout
        expect(result).to_not match(/crashkernel/)
        expect(check_for_package(host, 'kexec-tools')).to be false
      end

    end

    context 'with enabled = true' do
      it 'should apply manifest2' do
        apply_manifest_on(host, manifest2, :catch_changes => true)
      end

      it 'should reboot and set kernel param' do
        host.reboot
        result = on(host, %(cat /proc/cmdline)).stdout
        expect(result).to match(/crashkernel=auto/)
        expect(check_for_package(host, 'kexec-tools')).to be true
      end
    end

  end
end
