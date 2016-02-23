require 'spec_helper'

describe 'simp::yum_server' do
  base_facts = {
    :osfamily => 'RedHat',
    :hardwaremodel => 'x86_64',
    :selinux_enforced => true,
    :operatingsystem => 'RedHat',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.6',
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
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_apache__add_site('yum') }
  end
end
