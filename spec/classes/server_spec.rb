require 'spec_helper'

describe 'simp::server' do
  base_facts = {
    :osfamily => 'RedHat',
    :processorcount => 2,
    :operatingsystem => 'CentOS',
    :operatingsystemmajrelease => '6',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.5',
    :ipaddress => '10.10.10.10',
    :fqdn => 'foo.bar.baz',
    :hostname => 'foo',
    :interfaces => 'eth0',
    :ipaddress_eth0 => '10.10.10.10',
    :trusted => {
      :certname => 'foo.bar.baz'
    },
    # To provide the passenger_root fact
    :passenger_root => '/var/run/passenger',
    # For the server tests
    :spec_title => 'puppet_server',
    :passenger_version => '4',
    :selinux_current_mode => 'enforcing',
    :grub_version => '0.9',
    :uid_min => '500',
    :apache_version => '2.2',
    :init_systems => ['rc','sysv','upstart']
  }

  let(:facts){base_facts}

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('acpid') }
  it { is_expected.to create_class('pupmod::master') }
  it { is_expected.to create_class('simp::server') }
  it { is_expected.to create_rsync__server__section('default') }
end
