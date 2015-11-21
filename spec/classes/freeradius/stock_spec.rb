require 'spec_helper'

describe 'simp::freeradius::stock' do
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
    },

  }

  let(:facts) {base_facts}

  it { should compile.with_all_deps }

  it { should contain_class('freeradius::users') }
  it { should contain_class('freeradius::conf::client') }
  it { should contain_class('freeradius::conf') }

  # Check to ensure the client is added
  it { should create_file('/etc/raddb/conf/clients/default.conf').with_content(/ipaddr = 127.0.0.1/) }

  # Check to ensure that the default_auth listen is added
  it { should create_file('/etc/raddb/conf/listen.inc/default_auth').with_content(/type = auth/) }

  # Check to ensure default users are added (default_ppp, default_cslip, default_slip)
  it { should create_file('/etc/raddb/users.inc/100.default_ppp').with_content(/Framed-Protocol = PPP/) }
  it { should create_file('/etc/raddb/users.inc/100.default_cslip').with_content(/Hint == "CSLIP"/) }
  it { should create_file('/etc/raddb/users.inc/100.default_slip').with_content(/Hint == "SLIP"/) }
end
