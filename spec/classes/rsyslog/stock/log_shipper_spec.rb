require 'spec_helper'

describe 'simp::rsyslog::stock::log_shipper' do
  let(:facts) {{
    :interfaces => 'eth0, lo',
    :operatingsystem => 'RedHat',
    :lsbmajdistrelease => '6',
    :lsbdistrelease => '6.6',
    :passenger_version => '4',
    :selinux_current_mode => 'enforcing',
    :grub_version => '0.9',
    :uid_min => '500',
    :apache_version => '2.2',
    :init_systems => ['rc','sysv','upstart'],
    :trusted => {
      :certname => 'foo.bar.baz'
    }
  }}

  let(:params) {{
    :log_servers => ['1.2.3.4','5.6.7.8'],
    :failover_log_servers => ['1.1.1.1']
  }}

  it { should compile.with_all_deps }
  it { should create_class('simp::rsyslog::stock::log_shipper') }
end
