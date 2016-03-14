require 'spec_helper'

describe 'simp::rsyslog::stock' do
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
          it { is_expected.to create_class('rsyslog') }
        end

        context 'as a log server' do
          let(:params){{
            :is_server => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::rsyslog::stock::log_server') }
          it { is_expected.to create_file('/etc/rsyslog.conf') }
          it { is_expected.to create_file('/etc/cron.hourly/logrotate') }
          it { is_expected.to create_file('/etc/cron.daily/logrotate').with_ensure('absent') }
          it { is_expected.to create_file('/etc/cron.monthly/logrotate').with_ensure('absent') }
          it { is_expected.to create_file('/etc/cron.yearly/logrotate').with_ensure('absent') }
        end
      end
    end
  end
end
