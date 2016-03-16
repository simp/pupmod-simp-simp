require 'spec_helper'

describe 'simp::nfs::export_home' do
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

        let(:params){{ :data_dir => '/var' }}

        it { is_expected.to create_class('simp::nfs::export_home') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('nfs') }
        it { is_expected.to contain_class('nfs::idmapd') }
        it { is_expected.to contain_class('nfs::server') }
        it { is_expected.to create_file('/var/nfs/exports').with_ensure('directory') }
        it { is_expected.to create_file('/var/nfs/exports/home').with_ensure('directory') }
        it { is_expected.to create_file('/var/nfs/home').with_ensure('directory') }
      end
    end
  end
end
