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

          facts[:simp_rsync_environments] = ['production', 'simp']

          facts
        end

        simp_server_rsync_base = {}

        before(:each) do
          Puppet::Parser::Functions.newfunction(:simp_server_rsync_base, :type => :rvalue) { |args|
            simp_server_rsync_base.call(args[0])
          }

          simp_server_rsync_base.stubs(:call).returns(['simp','production'])
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to create_class('simp::server::rsync_shares') }
          it { is_expected.not_to create_pam__access__rule('allow_simp') }
          it { is_expected.not_to create_sudo__user_specification('default_simp') }
        end

        context 'with allow_simp_user => true' do
          let(:params){{
            :pam => true,
            :allow_simp_user => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to create_class('simp::server::rsync_shares') }
          it { is_expected.to create_pam__access__rule('allow_simp') }
          it { is_expected.to create_sudo__user_specification('default_simp') }
        end

        context 'without rsync shares' do
          let(:params){{
            :enable_rsync_shares => false
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to_not create_class('simp::server::rsync_shares') }
        end
      end
    end
  end
end
