require 'spec_helper'

describe 'simp::kmod_blacklist' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
        else
          let(:stock_blacklist) do
            ['bluetooth', 'cramfs', 'dccp', 'dccp_ipv4',
             'dccp_ipv6', 'freevxfs', 'hfs', 'hfsplus',
             'ieee1394', 'jffs2', 'net-pf-31', 'rds', 'sctp',
             'squashfs', 'tipc', 'udf', 'usb-storage']
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::kmod_blacklist') }

          it 'blacklists all the default kmods' do
            is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content(stock_blacklist.map { |x| "install #{x} /bin/true" }.join("\n") + "\n")

            stock_blacklist.each do |mod|
              is_expected.to create_kmod__blacklist(mod)
              is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_ensure('absent')
            end
          end

          context 'when disabling overrides' do
            let(:params) do
              {
                allow_overrides: false,
              }
            end

            it 'blacklists all the default kmods authoritatively' do
              is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_content(stock_blacklist.map { |x| "install #{x} /bin/true" }.join("\n") + "\n")

              stock_blacklist.each do |mod|
                is_expected.to create_kmod__blacklist(mod)
                is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_ensure('absent')
              end
            end
          end

          context 'with custom kmods' do
            let(:custom_list) { ['nfs', 'fuse'] }
            let(:params) { { custom_blacklist: custom_list } }

            it 'includes all the kmods in the blacklist' do
              is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content((custom_list + stock_blacklist).map { |x| "install #{x} /bin/true" }.join("\n") + "\n")

              (stock_blacklist + custom_list).each do |mod|
                is_expected.to create_kmod__blacklist(mod)
              end
            end
          end

          context 'with the default list disabled' do
            let(:custom_list) { ['nfs', 'fuse'] }
            let(:params) do
              {
                enable_defaults: false,
                custom_blacklist: custom_list,
              }
            end

            it 'includes only the custom the kmods in the blacklist' do
              is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content(custom_list.map { |x| "install #{x} /bin/true" }.join("\n") + "\n")

              custom_list.each do |mod|
                is_expected.to create_kmod__blacklist(mod)
              end
            end

            it 'removes the default kmods from the blacklist' do
              stock_blacklist.each do |mod|
                is_expected.to create_kmod__blacklist(mod).with_ensure('absent')
              end
            end
          end

          context 'when locking modules' do
            let(:params) do
              {
                lock_modules: true,
              }
            end

            context 'when able to find kernel.modules_disabled' do
              let(:facts) do
                updated_facts = Marshal.load(Marshal.dump(os_facts))
                updated_facts['simplib_sysctl'] = {
                  'kernel.modules_disabled' => 0,
                }

                updated_facts
              end

              it 'safelies lock the modules' do
                is_expected.to create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
                is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('simp_modprobe_lock')
                is_expected.to create_sysctl('kernel.modules_disabled').with_value(1)
              end
            end

            context 'when unable to find kernel.modules_disabled' do
              let(:facts) do
                updated_facts = Marshal.load(Marshal.dump(os_facts))
                updated_facts['simplib_sysctl'] = {
                  'kernel.modules_disabled' => nil,
                }

                updated_facts
              end

              it 'warns that it cannot lock the modules' do
                is_expected.not_to create_stage('simp_modprobe_lock')
                is_expected.not_to create_class('simp::kmod_blacklist::lock_modules')
                is_expected.not_to create_sysctl('kernel.modules_disabled')
                is_expected.to create_notify('simp::kmod_blacklist cannot lock modules')
              end
            end
          end

          context 'when unlocking modules on an unlocked system' do
            let(:params) do
              {
                lock_modules: false,
              }
            end
            let(:facts) do
              updated_facts = Marshal.load(Marshal.dump(os_facts))
              updated_facts['simplib_sysctl'] = {
                'kernel.modules_disabled' => 0,
              }

              updated_facts
            end

            it 'does not lock the modules or change the settings' do
              is_expected.not_to create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
              is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('main')
              is_expected.not_to create_sysctl('kernel.modules_disabled')
              is_expected.not_to create_reboot_notify('kernel.modules_disabled unlock')
            end
          end

          context 'when unlocking modules on a locked system' do
            let(:params) do
              {
                lock_modules: false,
              }
            end
            let(:facts) do
              updated_facts = Marshal.load(Marshal.dump(os_facts))
              updated_facts['simplib_sysctl'] = {
                'kernel.modules_disabled' => 1,
              }

              updated_facts
            end

            it 'unlocks the modules and notify for reboot' do
              is_expected.not_to create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
              is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('main')
              is_expected.to create_sysctl('kernel.modules_disabled').with_value(0)
              is_expected.to create_reboot_notify('kernel.modules_disabled unlock')
            end
          end

          context 'when unlocking modules on a locked system and not notifying for reboot' do
            let(:params) do
              {
                lock_modules: false,
                notify_if_reboot_required: false,
              }
            end
            let(:facts) do
              updated_facts = Marshal.load(Marshal.dump(os_facts))
              updated_facts['simplib_sysctl'] = {
                'kernel.modules_disabled' => 1,
              }

              updated_facts
            end

            it 'unlocks the modules but not notify for reboot' do
              is_expected.not_to create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
              is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('main')
              is_expected.to create_sysctl('kernel.modules_disabled').with_value(0)
              is_expected.to create_reboot_notify('kernel.modules_disabled unlock').with_ensure('absent')
            end
          end

          context 'when producing an error on module load' do
            let(:params) do
              {
                produce_error: true,
              }
            end

            it 'blacklists all the default kmods and point to /bin/false' do
              is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content(stock_blacklist.map { |x| "install #{x} /bin/false" }.join("\n") + "\n")
            end
          end

        end
      end
    end
  end
end
