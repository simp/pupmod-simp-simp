require 'spec_helper_acceptance'

test_name 'simp::kmod_blacklist class'

describe 'simp::kmod_blacklist class' do
  let(:manifest) {
    <<-EOS
      include 'simp::kmod_blacklist'
    EOS
  }

  hosts.each do |host|
    context 'default parameters' do
      it 'should apply with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should have blacklisted bluetooth' do
        on(host, 'modprobe -c | grep -qx "blacklist bluetooth"')
      end

      it 'should have disabled bluetooth loading' do
        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'", :acceptable_exit_codes => [1])
      end

      it 'should allow bluetooth disable to be locally overridable' do
        on(host, %(echo 'install bluetooth /sbin/insmod `/sbin/modinfo -F filename bluetooth` $CMDLINE_OPTS' > /etc/modprobe.d/my_bluetooth.conf))

        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'")
        on(host, 'rmmod bluetooth')
      end

      it 'should not prevent manual loading of the bluetooth module' do
        on(host, %(/sbin/insmod `/sbin/modinfo -F filename bluetooth`))

        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'")
        on(host, 'rmmod bluetooth')
      end
    end

    context 'disabling the ability to override modules' do
      it 'should disallow overrides via hiera' do
        yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
        default_yaml = yaml.merge(
          'simp::kmod_blacklist::allow_overrides' => false
        ).to_yaml
        create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
      end

      it 'should apply with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should allow bluetooth disable to be locally overridable' do
        on(host, %(echo 'install bluetooth /sbin/insmod `/sbin/modinfo -F filename bluetooth` $CMDLINE_OPTS' > /etc/modprobe.d/my_bluetooth.conf))

        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'", :acceptable_exit_codes => [1])
      end

      it 'should not prevent manual loading of the bluetooth module' do
        on(host, %(/sbin/insmod `/sbin/modinfo -F filename bluetooth`))

        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'")
        on(host, 'rmmod bluetooth')
      end
    end

    context 'disabling the ability to load modules' do
      it 'sets up a module for removal tests' do
        on(host, %(modprobe crypto_null))
      end

      it 'should lock via hiera' do
        yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
        default_yaml = yaml.merge(
          'simp::kmod_blacklist::allow_overrides' => nil,
          'simp::kmod_blacklist::lock_modules'    => true
        ).to_yaml
        create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
      end

      it 'should apply with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should prevent manual loading of the bluetooth module' do
        on(host, %(/sbin/insmod `/sbin/modinfo -F filename bluetooth`), :acceptable_exit_codes => [1])

        on(host, 'modprobe bluetooth', :acceptable_exit_codes => [1])
      end

      it 'should prevent manual removal of a loaded module' do
        on(host, 'rmmod crypto_null', :acceptable_exit_codes => [1])
      end

      it 'should unlock on reboot' do
        host.reboot

        on(host, 'modprobe crypto_null')
        on(host, 'rmmod crypto_null')
      end
    end
  end
end
