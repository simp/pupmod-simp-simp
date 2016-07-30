require 'spec_helper'

describe 'simp::nfs::export_home' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) { facts }
        let(:params){{ :data_dir => '/var' }}
        let(:hieradata) { class_name }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::nfs::export_home') }
        it { is_expected.to contain_class('nfs') }
        it { is_expected.to contain_class('nfs::idmapd') }
        it { is_expected.to contain_class('nfs::server') }
        it { is_expected.to create_file('/var/nfs/exports').with_ensure('directory') }
        it { is_expected.to create_file('/var/nfs/exports/home').with_ensure('directory') }
        it { is_expected.to create_file('/var/nfs/home').with_ensure('directory') }
      end
    end
  end
end
