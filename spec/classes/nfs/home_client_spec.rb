require 'spec_helper'

describe 'simp::nfs::home_client' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) { facts }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::nfs::home_client') }
        it { is_expected.to contain_class('nfs') }
        it { is_expected.to contain_class('nfs::client') }
        it { is_expected.to contain_class('autofs') }
        it { is_expected.to contain_selboolean('use_nfs_home_dirs') }
      end
    end
  end
end
