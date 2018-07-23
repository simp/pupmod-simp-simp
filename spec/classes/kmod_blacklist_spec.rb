require 'spec_helper'

describe 'simp::kmod_blacklist' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts['augeasversion'] = '1.4.0'
          facts
        end

        let(:stock_blacklist) {
          ['bluetooth', 'cramfs', 'dccp', 'dccp_ipv4',
           'dccp_ipv6', 'freevxfs', 'hfs', 'hfsplus',
           'ieee1394', 'jffs2', 'net-pf-31', 'rds', 'sctp',
           'squashfs', 'tipc', 'udf', 'usb-storage']
        }

        if facts[:os][:release][:major] == '6'
          let(:early_prefix){ 'zz' }
          let(:late_prefix){ '00' }
        else
          let(:early_prefix){ '00' }
          let(:late_prefix){ 'zz' }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::kmod_blacklist') }

        it 'should blacklist all the default kmods' do
          is_expected.to create_file("/etc/modprobe.d/#{late_prefix}_simp_disable.conf").with_content(stock_blacklist.map{|x| x = "install #{x} /bin/true" }.join("\n") + "\n")

          stock_blacklist.each do |mod|
            is_expected.to create_kmod__blacklist(mod)
            is_expected.to create_file("/etc/modprobe.d/#{early_prefix}_simp_disable.conf").with_ensure('absent')
          end
        end

        context 'when disabling overrides' do
          let(:params){{
            :allow_overrides => false
          }}

          it 'should blacklist all the default kmods authoritatively' do
            is_expected.to create_file("/etc/modprobe.d/#{early_prefix}_simp_disable.conf").with_content(stock_blacklist.map{|x| x = "install #{x} /bin/true" }.join("\n") + "\n")

            stock_blacklist.each do |mod|
              is_expected.to create_kmod__blacklist(mod)
              is_expected.to create_file("/etc/modprobe.d/#{late_prefix}_simp_disable.conf").with_ensure('absent')
            end
          end
        end

        context 'with custom kmods' do
          let(:custom_list) { ['nfs','fuse'] }
          let(:params) {{ :custom_blacklist => custom_list }}
          it 'should include all the kmods in the blacklist' do
            is_expected.to create_file("/etc/modprobe.d/#{late_prefix}_simp_disable.conf").with_content((custom_list + stock_blacklist).map{|x| x = "install #{x} /bin/true" }.join("\n") + "\n")

            (stock_blacklist + custom_list).each do |mod|
              is_expected.to create_kmod__blacklist(mod)
            end
          end
        end

        context 'with the default list disabled' do
          let(:custom_list) { ['nfs','fuse'] }
          let(:params) {{
            :enable_defaults  => false,
            :custom_blacklist => custom_list
          }}
          it 'should include only the custom the kmods in the blacklist' do
            is_expected.to create_file("/etc/modprobe.d/#{late_prefix}_simp_disable.conf").with_content(custom_list.map{|x| x = "install #{x} /bin/true" }.join("\n") + "\n")

            custom_list.each do |mod|
              is_expected.to create_kmod__blacklist(mod)
            end
          end

          it 'should remove the default kmods from the blacklist' do
            stock_blacklist.each do |mod|
              is_expected.to create_kmod__blacklist(mod).with_ensure('absent')
            end
          end
        end

        context 'when locking modules' do
          let(:params) {{
            :lock_modules => true
          }}

          context 'when able to find kernel.modules_disabled' do
            let(:facts) do
              lfacts = facts.dup
              lfacts['simplib_sysctl'] = {
                'kernel.modules_disabled' => 0
              }

              lfacts
            end

            it 'should safely lock the modules' do
              is_expected.to create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
              is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('simp_modprobe_lock')
              is_expected.to create_sysctl('kernel.modules_disabled').with_value(1)
            end
          end

          context 'when unable to find kernel.modules_disabled' do
            let(:facts) do
              lfacts = facts.dup
              lfacts['simplib_sysctl'] = {
                'kernel.modules_disabled' => nil
              }

              lfacts
            end

            it 'should warn that it cannot lock the modules' do
              is_expected.to_not create_stage('simp_modprobe_lock')
              is_expected.to_not create_class('simp::kmod_blacklist::lock_modules')
              is_expected.to_not create_sysctl('kernel.modules_disabled')
              is_expected.to create_notify('simp::kmod_blacklist cannot lock modules')
            end
          end
        end

        context 'when unlocking modules on an unlocked system' do
          let(:params) {{
            :lock_modules => false
          }}
          let(:facts) do
            lfacts = facts.dup
            lfacts['simplib_sysctl'] = {
              'kernel.modules_disabled' => 0
            }

            lfacts
          end

          it 'should not lock the modules or change the settings' do
            is_expected.to_not create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
            is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('main')
            is_expected.to_not create_sysctl('kernel.modules_disabled')
            is_expected.to_not create_reboot_notify('kernel.modules_disabled unlock')
          end
        end

        context 'when unlocking modules on a locked system' do
          let(:params) {{
            :lock_modules => false
          }}
          let(:facts) do
            lfacts = facts.dup
            lfacts['simplib_sysctl'] = {
              'kernel.modules_disabled' => 1
            }

            lfacts
          end

          it 'should unlock the modules and notify for reboot' do
            is_expected.to_not create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
            is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('main')
            is_expected.to create_sysctl('kernel.modules_disabled').with_value(0)
            is_expected.to create_reboot_notify('kernel.modules_disabled unlock')
          end

        end

        context 'when unlocking modules on a locked system and not notifying for reboot' do
          let(:params) {{
            :lock_modules              => false,
            :notify_if_reboot_required => false
          }}
          let(:facts) do
            lfacts = facts.dup
            lfacts['simplib_sysctl'] = {
              'kernel.modules_disabled' => 1
            }

            lfacts
          end

          it 'should unlock the modules but not notify for reboot' do
            is_expected.to_not create_stage('simp_modprobe_lock').that_requires('Stage[simp_finalize]')
            is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_stage('main')
            is_expected.to create_sysctl('kernel.modules_disabled').with_value(0)
            is_expected.to create_reboot_notify('kernel.modules_disabled unlock').with_ensure('absent')
          end

        end

      end
    end
  end
end
