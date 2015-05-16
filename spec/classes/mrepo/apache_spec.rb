require 'spec_helper'

describe 'simp::mrepo::apache' do
  let(:facts) {{
    :operatingsystem => 'CentOS',
    :lsbmajdistrelease => '6',
    :lsbdistrelease => '6.5',
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
  }}

  it { should create_class('simp::mrepo::apache') }
  it { should compile.with_all_deps }
  it { should create_file('/etc/httpd/conf.d/mrepo.conf') }
end
