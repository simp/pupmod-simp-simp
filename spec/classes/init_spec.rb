require 'spec_helper'

describe 'simp' do
  base_facts = {
    :operatingsystem => 'CentOS',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.5',
    :operatingsystemmajrelease => '6.5',
    :ipaddress => '10.10.10.10',
    :fqdn => 'foo.bar.baz',
    :hostname => 'foo',
    :hardwaremodel => 'x86_64',
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

  before(:each) do
    mod_site_pp("hiera_include('classes')")
  end

  it { should compile.with_all_deps }

  context 'with_puppet_server' do
    let(:params) {{ :puppet_server_ip => '1.2.3.4' }}

    it { should create_host('puppet.bar.baz').with_ip('1.2.3.4') }
  end
end
