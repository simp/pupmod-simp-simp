require 'spec_helper'

describe 'simp::nfs::export_home' do
  let(:facts) {{
    :osfamily => 'RedHat',
    :interfaces => 'eth0, lo',
    :operatingsystem => 'RedHat',
    :operatingsystemmajrelease => '6',
    :operatingsystemrelease => '6.6',
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

  let(:params){{ :data_dir => '/var' }}

  it { is_expected.to create_class('simp::nfs::export_home') }
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_class('nfs') }
  it { is_expected.to contain_class('nfs::idmapd') }
  it { is_expected.to contain_class('nfs::server') }
  it { is_expected.to create_file('/var/nfs/exports').with_ensure('directory') }
  it { is_expected.to create_file('/var/nfs/exports/home').with_ensure('directory') }
  it { is_expected.to create_file('/var/nfs/home').with_ensure('directory') }
end
