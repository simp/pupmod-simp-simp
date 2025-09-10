require 'spec_helper_acceptance'

test_name 'simp::kmod_blacklist class'

describe 'simp::kmod_blacklist class' do
  let(:manifest) do
    <<-EOS
      include 'simp::kmod_blacklist'
    EOS
  end

  hosts.each do |host|
    context 'default parameters' do
      it 'applies with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'has blacklisted bluetooth' do
        on(host, 'modprobe -c | grep -qx "blacklist bluetooth"')
      end

      it 'has disabled bluetooth loading' do
        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'", acceptable_exit_codes: [1])
      end

      it 'allows bluetooth disable to be locally overridable' do
        on(host, %(echo 'install bluetooth /sbin/insmod `/sbin/modinfo -F filename bluetooth` $CMDLINE_OPTS' > /etc/modprobe.d/my_bluetooth.conf))

        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'")
        on(host, 'rmmod bluetooth')
      end

      it 'does not prevent manual loading of the bluetooth module' do
        on(host, %(/sbin/insmod `/sbin/modinfo -F filename bluetooth`))

        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'")
        on(host, 'rmmod bluetooth')
      end
    end

    context 'disabling the ability to override modules' do
      let(:hieradata)  do
        YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
          {
            'simp::kmod_blacklist::allow_overrides' => false,
          },
        )
      end

      it 'disallows overrides via hiera' do
        set_hieradata_on(host, hieradata)
      end

      it 'applies with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'allows bluetooth disable to be locally overridable' do
        on(host, %(echo 'install bluetooth /sbin/insmod `/sbin/modinfo -F filename bluetooth` $CMDLINE_OPTS' > /etc/modprobe.d/my_bluetooth.conf))

        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'", acceptable_exit_codes: [1])
      end

      it 'does not prevent manual loading of the bluetooth module' do
        on(host, %(/sbin/insmod `/sbin/modinfo -F filename bluetooth`))

        on(host, 'modprobe bluetooth')
        on(host, "lsmod | cut -f1 -d' ' | grep -qx 'bluetooth'")
        on(host, 'rmmod bluetooth')
      end
    end

    context 'disabling the ability to load modules' do
      let(:hieradata)  do
        YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
          {
            'simp::kmod_blacklist::allow_overrides' => nil,
            'simp::kmod_blacklist::lock_modules'    => true,
          },
        )
      end

      it 'sets up a module for removal tests' do
        on(host, %(modprobe snd_usb_audio))
      end

      it 'locks via hiera' do
        set_hieradata_on(host, hieradata)
      end

      it 'applies with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'prevents manual loading of the bluetooth module' do
        on(host, %(/sbin/insmod `/sbin/modinfo -F filename bluetooth`), acceptable_exit_codes: [1])

        on(host, 'modprobe bluetooth', acceptable_exit_codes: [1])
      end

      it 'prevents manual removal of a loaded module' do
        on(host, 'rmmod snd_usb_audio', acceptable_exit_codes: [1])
      end

      it 'unlocks on reboot' do
        host.reboot

        on(host, 'modprobe snd_usb_audio')
        on(host, 'rmmod snd_usb_audio')
      end
    end
  end
end
