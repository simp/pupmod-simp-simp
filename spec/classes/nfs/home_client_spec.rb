require 'spec_helper'

describe 'simp::nfs::home_client' do
  let(:facts) {{
    :interfaces => 'eth0, lo',
    :operatingsystem => 'RedHat',
    :operatingsystemrelease => '6.6',
    :operatingsystemmajrelease => '6',
    :passenger_version => '4',
    :selinux_current_mode => 'enforcing',
    :grub_version => '0.9',
    :uid_min => '500',
    :apache_version => '2.2',
    :init_systems => ['rc','sysv','upstart'],
    :trusted => {
      :certname => 'foo.bar.baz'
    }
  }}

  it { should create_class('simp::nfs::home_client') }
  it { should compile.with_all_deps }
  it { should contain_class('nfs') }
  it { should contain_class('nfs::client') }
  it { should contain_class('autofs') }
  it { should contain_selboolean('use_nfs_home_dirs') }
end
