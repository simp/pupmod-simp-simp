require 'spec_helper'

describe 'simp::nfs::create_home_dirs' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:pre_condition) { 'include "nfs"' }
        let(:facts) { facts }

        it { is_expected.to create_class('simp::nfs::create_home_dirs') }

        context 'base' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::nfs::create_home_dirs') }
          it { is_expected.to contain_class('nfs') }

          it { is_expected.to contain_package('rubygem-net-ldap') }
          it { is_expected.to create_file('/etc/cron.hourly/create_home_directories.rb') }
        end
      end
    end
  end
end
