require 'spec_helper'

describe 'simp::yum_server' do
  base_facts = {
    :hardwaremodel => 'x86_64',
    :selinux_enforced => true,
    :operatingsystem => 'RedHat',
    :lsbmajdistrelease => '6',
    :lsbdistrelease => '6.6',
    :passenger_version => '4',
    :selinux_current_mode => 'enforcing',
    :grub_version => '0.9',
    :uid_min => '500',
    :apache_version => '2.2',
    :init_systems => ['rc','sysv','upstart'],
    :interfaces => 'eth0',
    :ipaddress_eth0 => '10.10.10.10',
    :trusted => {
      :certname => 'foo.bar.baz'
    }
  }
  let(:facts){base_facts}

  context 'base' do
    it { should compile.with_all_deps }
    it { should contain_apache__add_site('yum') }
  end
end
