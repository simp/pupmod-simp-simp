require 'spec_helper'

describe 'simp::mountpoints' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          # facts[:selinux_mode] = 'disabled'
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_mount('/dev/pts').with_options('rw,gid=5,mode=620,noexec') }
          it { is_expected.to contain_mount('/sys').with_options('rw,nodev,noexec') }
          it { is_expected.to contain_file('/tmp').that_comes_before('Mount[/tmp]') }
          it { is_expected.to contain_file('/var/tmp').that_comes_before('Mount[/var/tmp]') }
        end

        context 'and manage_tmp_perms => false' do
          let(:params) {{ :manage_tmp_perms => false }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_mount('/tmp') }
          it { is_expected.not_to contain_mount('/var/tmp') }
          it { is_expected.not_to contain_file('/tmp') }
          it { is_expected.not_to contain_file('/var/tmp') }
        end

      end
    end
  end
end
