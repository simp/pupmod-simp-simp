require 'spec_helper'

describe 'simp::kickstart_server' do
  base_facts = {
    :domain => 'bar.baz',
    :operatingsystem => 'CentOS',
    :lsbmajdistrelease => '6',
    :lsbdistrelease => '6.5',
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
  let(:params){{:data_dir => '/var/www'}}

  it { should compile.with_all_deps }
  it { should create_class('apache') }
  it { should create_class('dhcp::dhcpd') }
  it { should create_class('tftpboot') }
  it { should create_apache__add_site('ks').with_content(/Allow from 1.2.3.4\/24/) }
  it { should create_file('/var/www/ks').with_mode('2640') }
  it { should create_file('/var/www/ks/runpuppet').with_content(/puppet=.*--waitforcert 10.*--evaltrace --summarize/) }
  it { should create_file('/var/www/ks/runpuppet').with_content(/puppet_server="puppet.bar.baz"/) }
  it { should create_file('/var/www/ks/runpuppet').with_content(/ca_server = puppet.bar.baz/) }
  it { should create_file('/var/www/ks/runpuppet').with_content(/ca_port = 8141/) }
  it { should_not create_file('/var/www/ks/runpuppet').with_content(/ntpdate/) }

  context 'alternate_data_dir' do
    let(:params){{ :data_dir => '/srv/www' }}
    it { should create_file('/var/www/ks').with_target('/srv/www/ks') }
  end

  context 'specify_ntp_servers_array' do
    let(:params){{ :data_dir => '/var/www', :ntp_servers => ['1.2.3.4','5.6.7.8'] }}

    it { should compile.with_all_deps }
    it { should create_file('/var/www/ks/runpuppet').with_content(/ntpdate -b 1.2.3.4 5.6.7.8/) }
  end

  context 'specify_ntp_servers_hash' do
    let (:params){{ :data_dir => '/var/www', :ntp_servers => { '1.2.3.4' => ['foo, bar'], '5.6.7.8' => ['baz'] } }}

    it { should compile.with_all_deps }
    it { should create_file('/var/www/ks/runpuppet').with_content(/ntpdate -b 1.2.3.4 5.6.7.8/) }
  end

  context 'no_print_stats' do
    let(:params){{ :data_dir => '/var/www', :runpuppet_print_stats => false }}

    it { should compile.with_all_deps }
    it { should_not create_file('/var/www/ks/runpuppet').with_content(/--evaltrace/) }
  end

  context 'no_wait_for_cert' do
    let(:params){{ :data_dir => '/var/www', :runpuppet_wait_for_cert => '' }}

    it { should compile.with_all_deps }
    it { should_not create_file('/var/www/ks/runpuppet').with_content(/--waitforcert/) }
  end
end
