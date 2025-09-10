require 'spec_helper'

describe 'simp::version' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:root_dir) { (os_facts[:kernel] == 'windows') ? 'C:/ProgramData/SIMP' : '/etc/simp' }
        let(:root_dir_user) { (os_facts[:kernel] == 'windows') ? 'BUILTIN\Administrators' : 'root' }
        let(:root_dir_mode) { (os_facts[:kernel] == 'windows') ? '0775' : '0644' }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::version') }

        it {
          is_expected.to create_file(root_dir).with(
            {
              ensure: 'directory',
              owner: root_dir_user,
              group: root_dir_user,
              mode: root_dir_mode,
            },
          )
        }

        it {
          is_expected.to create_file("#{root_dir}/simp.version").with(
            {
              ensure: 'file',
              owner: root_dir_user,
              group: root_dir_user,
              mode: root_dir_mode,
            },
          )
        }

        unless os_facts[:kernel] == 'windows'
          it { is_expected.to create_file('/usr/local/sbin/simp') }
        end
      end
    end
  end
end
