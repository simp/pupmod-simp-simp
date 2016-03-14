require 'spec_helper'

describe 'simp::server' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          if ['RedHat','CentOS'].include?(facts[:operatingsystem]) && facts[:operatingsystemmajrelease].to_s < '7'
            facts[:apache_version] = '2.2'
            facts[:grub_version] = '0.9'
            facts[:init_systems] = ['rc','sysv','upstart']
          else
            facts[:apache_version] = '2.4'
            facts[:grub_version] = '2.0~beta'
            facts[:init_systems] = ['rc','sysv','systemd']
          end

          facts[:selinux_current_mode] = 'enforcing'

          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('pupmod::master') }
          it { is_expected.to_not create_class('puppetdb::master::config') }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to create_class('simp::server::rsync_shares') }
          it { is_expected.to create_pam__access__manage('allow_simp') }
          it { is_expected.to create_sudo__user_specification('default_simp') }
        end

        context 'with puppetdb' do
          let(:params){{
            :enable_puppetdb => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('pupmod::master') }
          it { is_expected.to create_class('puppetdb::master::config') }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to create_class('simp::server::rsync_shares') }
          it { is_expected.to create_pam__access__manage('allow_simp') }
          it { is_expected.to create_sudo__user_specification('default_simp') }
        end

        context 'without the simp user' do
          let(:params){{
            :allow_simp_user => false
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('pupmod::master') }
          it { is_expected.to_not create_class('puppetdb::master::config') }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to create_class('simp::server::rsync_shares') }
          it { is_expected.to_not create_pam__access__manage('allow_simp') }
          it { is_expected.to_not create_sudo__user_specification('default_simp') }
        end

        context 'without rsync shares' do
          let(:params){{
            :enable_rsync_shares => false
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('pupmod::master') }
          it { is_expected.to_not create_class('puppetdb::master::config') }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to_not create_class('simp::server::rsync_shares') }
          it { is_expected.to create_pam__access__manage('allow_simp') }
          it { is_expected.to create_sudo__user_specification('default_simp') }
        end
      end
    end
  end
end
