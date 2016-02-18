require 'spec_helper'

describe 'simp::rsyslog::stock::log_server' do

  let(:facts) {{
    :osfamily => 'RedHat',
    :operatingsystem => 'RedHat',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.6',
    :operatingsystemmajrelease => '6',
    :passenger_version => '4',
    :selinux_current_mode => 'enforcing',
    :grub_version => '0.9',
    :uid_min => '500',
    :apache_version => '2.2',
    :init_systems => ['rc','sysv','upstart'],
    :interfaces => 'lo',
    :ipaddress_lo => '127.0.0.1',
    :trusted => {
      :certname => 'foo.bar.baz'
    }
  }}

  it { is_expected.to create_class('simp::rsyslog::stock::log_server') }

  context 'base' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_file('/etc/rsyslog.conf') }
    it { is_expected.to create_file('/etc/cron.hourly/logrotate') }
    it { is_expected.to create_file('/etc/cron.daily/logrotate').with_ensure('absent') }
    it { is_expected.to create_file('/etc/cron.monthly/logrotate').with_ensure('absent') }
    it { is_expected.to create_file('/etc/cron.yearly/logrotate').with_ensure('absent') }
  end
end
