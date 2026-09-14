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
          let(:stock_modules) { stock_blacklist.to_h { |mod| [mod, {}] } }

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
                is_expected.not_to create_kmod__install(mod)
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
          # Opt-in: the `modules` Hash (the simp:defaults profile supplies the
          # SCAP list; see kmod_blacklist_simp_defaults_profile_spec.rb)
          # ------------------------------------------------------------------
          context 'with the SCAP modules' do
            let(:params) { { modules: stock_modules } }

            it { is_expected.to compile.with_all_deps }

            it 'blacklists and disables all the kmods' do
              is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_ensure('absent')

              stock_blacklist.each do |mod|
                is_expected.to create_kmod__blacklist(mod).with_ensure('present')
                is_expected.to create_kmod__install(mod).with(
                  ensure: 'present',
                  command: '/bin/true',
                  file: '/etc/modprobe.d/zz_simp_disable.conf',
                )
              end
            end

            it 'lets kmod create the disable file' do
              is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_ensure('file')
            end

            it 'does not manage module locking' do
              is_expected.not_to create_class('simp::kmod_blacklist::lock_modules')
              is_expected.not_to create_sysctl('kernel.modules_disabled')
            end

            context 'when disabling overrides' do
              let(:params) do
                {
                  modules: stock_modules,
                  allow_overrides: false,
                }
              end

              it 'disables all the kmods authoritatively' do
                is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_ensure('absent')

                stock_blacklist.each do |mod|
                  is_expected.to create_kmod__blacklist(mod)
                  is_expected.to create_kmod__install(mod).with_file('/etc/modprobe.d/00_simp_disable.conf')
                end
              end
            end

            context 'when producing an error on module load' do
              let(:params) do
                {
                  modules: stock_modules,
                  produce_error: true,
                }
              end

              it 'points the disabled kmods at /bin/false' do
                stock_blacklist.each do |mod|
                  is_expected.to create_kmod__install(mod).with_command('/bin/false')
                end
              end
            end

            context 'with a module set to absent' do
              let(:params) do
                {
                  modules: stock_modules.merge('usb-storage' => { 'ensure' => 'absent' }),
                }
              end

              it { is_expected.to compile.with_all_deps }

              it 'removes the blacklist and install entries for that module' do
                is_expected.to create_kmod__blacklist('usb-storage').with_ensure('absent')
                is_expected.to create_kmod__install('usb-storage').with_ensure('absent')
              end

              it 'still manages the other modules' do
                (stock_blacklist - ['usb-storage']).each do |mod|
                  is_expected.to create_kmod__blacklist(mod).with_ensure('present')
                  is_expected.to create_kmod__install(mod).with_ensure('present')
                end
              end
            end

            context 'with extra kmod::blacklist parameters' do
              let(:params) do
                {
                  modules: { 'nfs' => { 'file' => '/etc/modprobe.d/nfs.conf' } },
                }
              end

              it { is_expected.to compile.with_all_deps }

              it 'passes them through to kmod::blacklist' do
                is_expected.to create_kmod__blacklist('nfs').with_file('/etc/modprobe.d/nfs.conf')
                is_expected.to create_kmod__install('nfs').with_file('/etc/modprobe.d/zz_simp_disable.conf')
              end
            end
          end

          context 'with only a module set to absent' do
            let(:params) { { modules: { 'usb-storage' => { 'ensure' => 'absent' } } } }

            it { is_expected.to compile.with_all_deps }

            it 'removes the entries without adding any' do
              is_expected.to create_kmod__blacklist('usb-storage').with_ensure('absent')
              is_expected.to create_kmod__install('usb-storage').with_ensure('absent')
              is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_ensure('absent')
            end
          end

          # ------------------------------------------------------------------
          # Deprecated Array parameters
          # ------------------------------------------------------------------
          context 'with the deprecated Array parameters' do
            before(:each) do
              allow(Puppet).to receive(:deprecation_warning)
            end

            context 'blacklist' do
              let(:params) { { blacklist: stock_blacklist } }

              it { is_expected.to compile.with_all_deps }

              it 'blacklists and disables all the kmods' do
                stock_blacklist.each do |mod|
                  is_expected.to create_kmod__blacklist(mod).with_ensure('present')
                  is_expected.to create_kmod__install(mod).with_ensure('present')
                end
              end

              # rspec-puppet caches catalogs per parameter set, so use a
              # distinct one here to force a fresh compile for the mock
              context 'compiling a fresh catalog' do
                let(:params) { { blacklist: ['fuse'] } }

                it 'logs a deprecation warning' do
                  expect(Puppet).to receive(:deprecation_warning).with(%r{blacklist is deprecated}, 'simp::kmod_blacklist::blacklist')
                  catalogue
                end
              end
            end

            context 'custom_blacklist' do
              let(:params) { { custom_blacklist: ['nfs', 'fuse'] } }

              it { is_expected.to compile.with_all_deps }

              it 'blacklists and disables only the listed kmods' do
                ['nfs', 'fuse'].each do |mod|
                  is_expected.to create_kmod__blacklist(mod).with_ensure('present')
                  is_expected.to create_kmod__install(mod).with_ensure('present')
                end

                stock_blacklist.each do |mod|
                  is_expected.not_to create_kmod__blacklist(mod)
                end
              end

              context 'compiling a fresh catalog' do
                let(:params) { { custom_blacklist: ['fuse'] } }

                it 'logs a deprecation warning' do
                  expect(Puppet).to receive(:deprecation_warning).with(%r{custom_blacklist is deprecated}, 'simp::kmod_blacklist::custom_blacklist')
                  catalogue
                end
              end
            end

            context 'blacklist and custom_blacklist combined with modules' do
              let(:params) do
                {
                  blacklist: ['bluetooth', 'cramfs'],
                  custom_blacklist: ['bluetooth', 'nfs'],
                  modules: { 'cramfs' => { 'ensure' => 'absent' }, 'fuse' => {} },
                }
              end

              it { is_expected.to compile.with_all_deps }

              it 'de-duplicates and lets modules win' do
                is_expected.to create_kmod__blacklist('bluetooth').with_ensure('present')
                is_expected.to create_kmod__blacklist('nfs').with_ensure('present')
                is_expected.to create_kmod__blacklist('fuse').with_ensure('present')
                is_expected.to create_kmod__blacklist('cramfs').with_ensure('absent')
                is_expected.to create_kmod__install('cramfs').with_ensure('absent')
              end
            end

            context 'enable_defaults set to false' do
              let(:params) do
                {
                  enable_defaults: false,
                  blacklist: stock_blacklist,
                  custom_blacklist: ['nfs'],
                }
              end

              it { is_expected.to compile.with_all_deps }

              context 'compiling a fresh catalog' do
                let(:params) { super().merge(custom_blacklist: ['fuse']) }

                it 'logs a deprecation warning' do
                  expect(Puppet).to receive(:deprecation_warning).with(%r{enable_defaults is deprecated}, 'simp::kmod_blacklist::enable_defaults')
                  catalogue
                end
              end

              it 'ignores blacklist and only uses custom_blacklist, as before 10.0.0' do
                is_expected.to create_kmod__blacklist('nfs').with_ensure('present')
                is_expected.to create_kmod__install('nfs').with_ensure('present')

                stock_blacklist.each do |mod|
                  is_expected.not_to create_kmod__blacklist(mod)
                end
              end
            end

            context 'enable_defaults set to true' do
              let(:params) do
                {
                  enable_defaults: true,
                  blacklist: stock_blacklist,
                }
              end

              it { is_expected.to compile.with_all_deps }

              it 'has no effect on the blacklist' do
                stock_blacklist.each do |mod|
                  is_expected.to create_kmod__blacklist(mod).with_ensure('present')
                end
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
