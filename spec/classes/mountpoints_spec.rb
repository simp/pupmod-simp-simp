require 'spec_helper'

describe 'simp::mountpoints' do
  on_supported_os({:selinux_mode => :disabled}).each do |os, os_facts|

    context "on #{os}" do
      let(:facts){ os_facts }
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_mount('/dev/pts').with_options('rw,gid=5,mode=620,noexec') }
      it { is_expected.to contain_mount('/sys').with_options('rw,nodev,noexec') }
      it { is_expected.to contain_mount('/tmp').with({
        :options => 'bind,nodev,noexec,nosuid',
        :device  => '/tmp'
      })}
      it { is_expected.to contain_mount('/var/tmp').with({
        :options => 'bind,nodev,noexec,nosuid',
        :device  => '/tmp'
      })}

      context 'tmp_is_partition' do
        let(:facts) do os_facts.merge({
            :tmp_mount_tmp        => 'rw,seclabel,relatime,data=ordered',
            :tmp_mount_fstype_tmp => 'ext4',
            :tmp_mount_path_tmp   => '/dev/sda3',
          })
        end
        it { is_expected.to contain_mount('/tmp').with({
          :options => 'data=ordered,nodev,noexec,nosuid,relatime,rw',
          :device  => '/dev/sda3'
        })}
      end

      context 'tmp_is_already_bind_mounted' do
        let(:facts) { os_facts.merge({
            :tmp_mount_tmp        => 'bind,foo',
            :tmp_mount_fstype_tmp => 'ext4',
            :tmp_mount_path_tmp   => '/tmp',
        })}
        it { is_expected.to contain_mount('/tmp').with({
          :options => "bind,nodev,noexec,nosuid",
          :device  => '/tmp'
        })}
      end

      context 'var_tmp_is_partition' do
        let(:facts) { os_facts.merge({
            :tmp_mount_var_tmp        => 'rw,seclabel,relatime,data=ordered',
            :tmp_mount_fstype_var_tmp => 'ext4',
            :tmp_mount_path_var_tmp   => '/dev/sda3',
        })}
        it { is_expected.to contain_mount('/var/tmp').with({
          :options => 'data=ordered,nodev,noexec,nosuid,relatime,rw',
          :device  => '/dev/sda3'
        })}
      end

      context 'var_tmp_is_already_bind_mounted' do
        let(:facts) { os_facts.merge({
            :tmp_mount_var_tmp        => 'bind,foo',
            :tmp_mount_fstype_var_tmp => 'ext4',
            :tmp_mount_path_var_tmp   => '/var/tmp',
        })}
        it { is_expected.to contain_mount('/var/tmp').with({
          :options => "bind,nodev,noexec,nosuid",
          :device  => facts[:tmp_mount_path_var_tmp]
        })}
      end

      context 'tmp_mount_dev_shm_mounted' do
        let(:facts) { os_facts.merge({
            :tmp_mount_dev_shm        => 'rw,seclabel,nosuid,nodev',
            :tmp_mount_fstype_dev_shm => 'tmpfs',
            :tmp_mount_path_dev_shm   => 'tmpfs',
        })}
        it { is_expected.to contain_mount('/dev/shm').with({
          :options => 'nodev,noexec,nosuid,rw',
          :device  => facts[:tmp_mount_path_dev_shm]
        })}
      end

      context 'when `::simp` is included' do
        let(:pre_condition){ 'include "simp"' }
        let(:facts){ os_facts.merge({
          :tmp_mount_tmp            => 'rw,relatime,data=ordered',
          :tmp_mount_fstype_tmp     => 'ext4',
          :tmp_mount_path_tmp       => '/dev/sda3',
          :tmp_mount_var_tmp        => 'rw,relatime,data=ordered',
          :tmp_mount_fstype_var_tmp => 'ext4',
          :tmp_mount_path_var_tmp   => '/dev/sda4',
        })}

        context 'and manage_tmp_perms => true' do
          let(:params) {{ :manage_tmp_perms => true }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/tmp').that_comes_before('Mount[/tmp]') }
          it { is_expected.to contain_file('/var/tmp').that_comes_before('Mount[/var/tmp]') }
        end

        context 'and manage_tmp_perms => false' do
          let(:params) {{ :manage_tmp_perms => false }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_mount('/tmp') }
          it { is_expected.to contain_mount('/var/tmp') }
          it { is_expected.not_to contain_file('/tmp') }
          it { is_expected.not_to contain_file('/var/tmp') }
        end
      end
    end
  end
end
