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

          # simp::rsyslog::stock::log_server
          it { is_expected.to create_class('simp::rsyslog::stock::log_server') }
          it { is_expected.to contain_rsyslog__template__string('sudosh_template') }
          it { is_expected.to contain_rsyslog__template__string('httpd_err_template') }
          it { is_expected.to contain_rsyslog__template__string('httpd_template') }
          it { is_expected.to contain_rsyslog__template__string('dhcpd_template') }
          it { is_expected.to contain_rsyslog__template__string('puppet_agent_err_template') }
          it { is_expected.to contain_rsyslog__template__string('puppet_agent_template') }
          it { is_expected.to contain_rsyslog__template__string('puppet_master_err_template') }
          it { is_expected.to contain_rsyslog__template__string('puppet_master_template') }
          it { is_expected.to contain_rsyslog__template__string('audit_template') }
          it { is_expected.to contain_rsyslog__template__string('slapd_audit_template') }
          it { is_expected.to contain_rsyslog__template__string('iptables_template') }
          it { is_expected.to contain_rsyslog__template__string('secure_template') }
          it { is_expected.to contain_rsyslog__template__string('messages_template') }
          it { is_expected.to contain_rsyslog__template__string('maillog_template') }
          it { is_expected.to contain_rsyslog__template__string('cron_template') }
          it { is_expected.to contain_rsyslog__template__string('spooler_template') }
          it { is_expected.to contain_rsyslog__template__string('boot_template') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_sudosh') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_httpd_error') }
          it { is_expected.to contain_rsyslog__rule__local('1_default_httpd') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_dhcpd') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_puppet_agent_error') }
          it { is_expected.to contain_rsyslog__rule__local('1_default_puppet_agent') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_puppet_master_error') }
          it { is_expected.to contain_rsyslog__rule__local('1_default_puppet_master') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_audit') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_slapd_audit') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_kern') }
          it { is_expected.to contain_rsyslog__rule__local('7_default_security_relevant_logs') }
          it { is_expected.to contain_rsyslog__rule__local('9_default_message') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_mail') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_cron') }
          it { is_expected.to contain_rsyslog__rule__console('0_default_emerg') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_spool') }
          it { is_expected.to contain_rsyslog__rule__local('0_default_boot') }

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
