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

          # ------------------------------------------------------------------
          # Safe default: a bare include manages nothing. These are the
          # regression guard for the 10.0.0 blast-radius reduction.
          # ------------------------------------------------------------------
          context 'with default parameters (bare include)' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::kmod_blacklist') }

            it 'does not touch /etc/modprobe.d' do
              is_expected.not_to create_file('/etc/modprobe.d/zz_simp_disable.conf')
              is_expected.not_to create_file('/etc/modprobe.d/00_simp_disable.conf')
              is_expected.not_to contain_class('kmod')

              stock_blacklist.each do |mod|
                is_expected.not_to create_kmod__blacklist(mod)
              end
            end

            it 'does not manage module locking' do
              is_expected.not_to create_class('simp::kmod_blacklist::lock_modules')
              is_expected.not_to create_stage('simp_modprobe_lock')
              is_expected.not_to create_sysctl('kernel.modules_disabled')
              is_expected.not_to create_notify('simp::kmod_blacklist cannot lock modules')
            end

            context 'on a system with kernel.modules_disabled available' do
              let(:facts) do
                os_facts.merge('simplib_sysctl' => { 'kernel.modules_disabled' => 0 })
              end

              it 'still does not manage module locking' do
                is_expected.not_to create_class('simp::kmod_blacklist::lock_modules')
                is_expected.not_to create_sysctl('kernel.modules_disabled')
              end
            end

            context 'on a system with kernel modules locked' do
              let(:facts) do
                os_facts.merge('simplib_sysctl' => { 'kernel.modules_disabled' => 1 })
              end

              it 'does not unlock the modules' do
                is_expected.not_to create_class('simp::kmod_blacklist::lock_modules')
                is_expected.not_to create_sysctl('kernel.modules_disabled')
                is_expected.not_to create_reboot_notify('kernel.modules_disabled unlock')
              end
            end
          end

          # ------------------------------------------------------------------
          # Opt-in: an explicit blacklist (the simp:defaults profile supplies
          # this list; see kmod_blacklist_simp_defaults_profile_spec.rb)
          # ------------------------------------------------------------------
          context 'with the SCAP blacklist' do
            let(:params) { { blacklist: stock_blacklist } }

            it { is_expected.to compile.with_all_deps }

            it 'blacklists all the default kmods' do
              is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content(stock_blacklist.map { |x| "install #{x} /bin/true" }.join("\n") + "\n")
              is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_ensure('absent')

              stock_blacklist.each do |mod|
                is_expected.to create_kmod__blacklist(mod).with_ensure('present')
              end
            end

            it 'does not manage module locking' do
              is_expected.not_to create_class('simp::kmod_blacklist::lock_modules')
              is_expected.not_to create_sysctl('kernel.modules_disabled')
            end

            context 'when disabling overrides' do
              let(:params) do
                {
                  blacklist: stock_blacklist,
                  allow_overrides: false,
                }
              end

              it 'blacklists all the default kmods authoritatively' do
                is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_content(stock_blacklist.map { |x| "install #{x} /bin/true" }.join("\n") + "\n")
                is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_ensure('absent')

                stock_blacklist.each do |mod|
                  is_expected.to create_kmod__blacklist(mod)
                end
              end
            end

            context 'with custom kmods' do
              let(:custom_list) { ['nfs', 'fuse'] }
              let(:params) do
                {
                  blacklist: stock_blacklist,
                  custom_blacklist: custom_list,
                }
              end

              it 'includes all the kmods in the blacklist' do
                is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content((custom_list + stock_blacklist).map { |x| "install #{x} /bin/true" }.join("\n") + "\n")

                (stock_blacklist + custom_list).each do |mod|
                  is_expected.to create_kmod__blacklist(mod)
                end
              end
            end

            context 'with a custom kmod that duplicates a blacklist entry' do
              let(:params) do
                {
                  blacklist: stock_blacklist,
                  custom_blacklist: ['bluetooth'],
                }
              end

              it { is_expected.to compile.with_all_deps }

              it 'lists the module once' do
                is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content(stock_blacklist.map { |x| "install #{x} /bin/true" }.join("\n") + "\n")
              end
            end

            context 'when producing an error on module load' do
              let(:params) do
                {
                  blacklist: stock_blacklist,
                  produce_error: true,
                }
              end

              it 'blacklists all the default kmods and point to /bin/false' do
                is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content(stock_blacklist.map { |x| "install #{x} /bin/false" }.join("\n") + "\n")
              end
            end
          end

          # ------------------------------------------------------------------
          # Opt-in: custom modules only
          # ------------------------------------------------------------------
          context 'with only custom kmods' do
            let(:custom_list) { ['nfs', 'fuse'] }
            let(:params) { { custom_blacklist: custom_list } }

            it { is_expected.to compile.with_all_deps }

            it 'includes only the custom kmods in the blacklist' do
              is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content(custom_list.map { |x| "install #{x} /bin/true" }.join("\n") + "\n")
              is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_ensure('absent')

              custom_list.each do |mod|
                is_expected.to create_kmod__blacklist(mod).with_ensure('present')
              end
            end

            it 'leaves the other kmods alone' do
              stock_blacklist.each do |mod|
                is_expected.not_to create_kmod__blacklist(mod)
              end
            end
          end

          # ------------------------------------------------------------------
          # Opt-in: removing previously-managed entries
          # ------------------------------------------------------------------
          context 'with purge_blacklist' do
            context 'and nothing blacklisted' do
              let(:params) { { purge_blacklist: ['usb-storage', 'bluetooth'] } }

              it { is_expected.to compile.with_all_deps }

              it 'removes the modules from the blacklist' do
                is_expected.to create_kmod__blacklist('usb-storage').with_ensure('absent')
                is_expected.to create_kmod__blacklist('bluetooth').with_ensure('absent')
              end

              it 'manages an empty disable file' do
                is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content("\n")
                is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_ensure('absent')
              end
            end

            context 'and a blacklist' do
              let(:params) do
                {
                  blacklist: stock_blacklist,
                  purge_blacklist: ['usb-storage', 'nfs'],
                }
              end

              it { is_expected.to compile.with_all_deps }

              it 'ignores purge entries that are still blacklisted' do
                is_expected.to create_kmod__blacklist('usb-storage').with_ensure('present')
                is_expected.to create_kmod__blacklist('nfs').with_ensure('absent')
              end
            end
          end

          # ------------------------------------------------------------------
          # Opt-in: module locking
          # ------------------------------------------------------------------
          context 'when locking modules' do
            let(:params) do
              {
                lock_modules: true,
              }
            end

            context 'when able to find kernel.modules_disabled' do
              let(:facts) do
                os_facts.merge('simplib_sysctl' => { 'kernel.modules_disabled' => 0 })
              end

              it 'safelies lock the modules' do
                is_expected.to create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
                is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('simp_modprobe_lock')
                is_expected.to create_sysctl('kernel.modules_disabled').with_value(1)
              end

              it 'does not touch /etc/modprobe.d' do
                is_expected.not_to create_file('/etc/modprobe.d/zz_simp_disable.conf')
                is_expected.not_to create_file('/etc/modprobe.d/00_simp_disable.conf')
              end
            end

            context 'when unable to find kernel.modules_disabled' do
              let(:facts) do
                os_facts.merge('simplib_sysctl' => { 'kernel.modules_disabled' => nil })
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
              os_facts.merge('simplib_sysctl' => { 'kernel.modules_disabled' => 0 })
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
              os_facts.merge('simplib_sysctl' => { 'kernel.modules_disabled' => 1 })
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
              os_facts.merge('simplib_sysctl' => { 'kernel.modules_disabled' => 1 })
            end

            it 'unlocks the modules but not notify for reboot' do
              is_expected.not_to create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
              is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('main')
              is_expected.to create_sysctl('kernel.modules_disabled').with_value(0)
              is_expected.to create_reboot_notify('kernel.modules_disabled unlock').with_ensure('absent')
            end
          end
        end
      end
    end
  end
end
