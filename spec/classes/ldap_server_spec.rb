require 'spec_helper'

describe 'simp::ldap_server' do
  base_facts = {
    :processorcount => 6,
    :operatingsystem => 'CentOS',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.5',
    :operatingsystemmajrelease => '6',
    :ipaddress => '10.10.10.10',
    :fqdn => 'foo.bar.baz',
    :hostname => 'foo',
    :interfaces => 'eth0',
    :ipaddress_eth0 => '10.10.10.10',
    :trusted => {
      :certname => 'foo.bar.baz'
    },
    :passenger_version => '4',
    :selinux_current_mode => 'enforcing',
    :grub_version => '0.9',
    :uid_min => '500',
    :apache_version => '2.2',
    :init_systems => ['rc','sysv','upstart']
  }

  let(:facts){base_facts}

  it { should compile.with_all_deps }

  context 'is_slave' do
    let(:params){{ :is_slave => true }}

    it { should compile.with_all_deps }
    it { should create_openldap__server__syncrepl('111') }
  end

  context 'use_lastbind' do
    let(:params){{ :enable_lastbind => true }}

    it { should compile.with_all_deps }
    it { should create_class('openldap::slapo::lastbind') }
  end
end
