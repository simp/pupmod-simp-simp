require 'spec_helper'

describe 'simp::freeradius::stock_ldap' do
  base_facts = {
    :osfamily => 'RedHat',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.6',
    :operatingsystem => 'RedHat',
    :hardwaremodel => 'x86_64',
    :passenger_version => '4',
    :selinux_current_mode => 'enforcing',
    :grub_version => '0.9',
    :uid_min => '500',
    :apache_version => '2.2',
    :init_systems => ['rc','sysv','upstart'],
    :interfaces => 'eth0',
    :trusted => {
      :certname => 'foo.bar.baz'
    }
  }

  let(:facts) {base_facts}

  it { is_expected.to create_class('simp::freeradius::stock_ldap') }
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_file('/etc/raddb/modules/ldap') }
end
