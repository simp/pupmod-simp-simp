require 'spec_helper'

describe 'simp::rsyslog::stock::log_server::forward' do

  let(:facts){{
    :osfamily => 'RedHat',
    :operatingsystem => 'RedHat',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.6',
    :interfaces => 'eth0',
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

  it { should create_class('simp::rsyslog::stock::log_server::forward') }

  context 'base' do
    it { should compile.with_all_deps }
  end
end
