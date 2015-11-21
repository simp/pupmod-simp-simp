require 'spec_helper'

describe 'simp::yum' do
  base_facts = {
    :osfamily => 'RedHat',
    :hardwaremodel             => 'x86_64',
    :operatingsystem           => 'CentOS',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease    => '6.5',
    :ipaddress                 => '10.10.10.10',
    :fqdn                      => 'foo.bar.baz',
    :hostname                  => 'foo',
    :interfaces                => 'eth0',
    :ipaddress_eth0            => '10.10.10.10',
    :trusted                   => {
      :certname  => 'foo.bar.baz'
    },
    :passenger_version         => '4',
    :selinux_current_mode      => 'enforcing',
    :grub_version              => '0.9',
    :uid_min                   => '500',
    :apache_version            => '2.2',
    :init_systems              => ['rc','sysv','upstart']
  }

  let(:facts){base_facts}

  let(:params){{
    :servers => ['yum1.bar.baz','yum2.bar.baz']
  }}

  it { should compile.with_all_deps }
  it { should create_yumrepo('simp').with({
      :gpgkey => %r(^https?://yum1.bar.baz/yum/SIMP),
      :baseurl => %r(^https?://yum1.bar.baz/yum/SIMP)
    })
  }
end
