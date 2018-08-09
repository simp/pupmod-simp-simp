require 'spec_helper'

describe 'simp::server::ldap' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          if ['RedHat', 'CentOS', 'OracleLinux'].include?(facts[:operatingsystem]) && facts[:operatingsystemmajrelease].to_s < '7'
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

        it { is_expected.to compile.with_all_deps }

        context 'is_slave' do
          let(:params){{ :is_slave => true }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_simp_openldap__server__syncrepl('111') }
        end

        context 'use_lastbind' do
          let(:params){{ :enable_lastbind => true }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_openldap::slapo::lastbind') }
        end
      end
    end
  end
end
