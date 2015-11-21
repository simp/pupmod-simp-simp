require 'spec_helper'

describe 'simp::rsyslog::stock' do
  let(:facts) {{
    :osfamily => 'RedHat',
    :interfaces => 'eth0, lo',
    :hardwaremodel => 'x86_64',
    :operatingsystem => 'RedHat',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.6',
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

  it { should compile.with_all_deps }
  it { should create_class('rsyslog') }
end
