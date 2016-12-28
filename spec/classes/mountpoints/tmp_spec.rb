require 'spec_helper'

describe 'simp::mountpoints::tmp' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to contain_mount('/tmp').with({
            :options => 'bind,nodev,noexec,nosuid',
            :device  => '/tmp'
          }) }
          it { is_expected.to contain_mount('/var/tmp').with({
            :options => 'bind,nodev,noexec,nosuid',
            :device  => '/tmp'
          }) }
          it { is_expected.to create_file('/tmp').with_mode('u+rwx,g+rwx,o+rwxt') }
          it { is_expected.to create_file('/var/tmp').with_mode('u+rwx,g+rwx,o+rwxt') }
          it { is_expected.to create_file('/usr/tmp').with_ensure('symlink') }
        end

        context 'tmp_is_partition' do
          let(:facts) do facts.merge({
              :tmp_mount_tmp        => 'rw,seclabel,relatime,data=ordered',
              :tmp_mount_fstype_tmp => 'ext4',
              :tmp_mount_path_tmp   => '/dev/sda3',
            })
          end
          it { is_expected.to contain_mount('/tmp').with({
            :options => 'data=ordered,nodev,noexec,nosuid,relatime,rw,seclabel',
            :device  => '/dev/sda3'
          })}
        end

        context 'tmp_is_already_bind_mounted' do
          let(:facts) { facts.merge({
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
          let(:facts) { facts.merge({
              :tmp_mount_var_tmp        => 'rw,seclabel,relatime,data=ordered',
              :tmp_mount_fstype_var_tmp => 'ext4',
              :tmp_mount_path_var_tmp   => '/dev/sda3',
          })}
          it { is_expected.to contain_mount('/var/tmp').with({
            :options => 'data=ordered,nodev,noexec,nosuid,relatime,rw,seclabel',
            :device  => '/dev/sda3'
          })}
        end

        context 'var_tmp_is_already_bind_mounted' do
          let(:facts) { facts.merge({
              :tmp_mount_var_tmp        => 'bind,foo',
              :tmp_mount_fstype_var_tmp => 'ext4',
              :tmp_mount_path_var_tmp   => '/var/tmp',
          })}
          it { is_expected.to contain_mount('/var/tmp').with({
            :options => "bind,nodev,noexec,nosuid",
            :device  => '/var/tmp'
          })}
        end

        context 'tmp_mount_dev_shm_mounted' do
          let(:facts) { facts.merge({
              :tmp_mount_dev_shm        => 'rw,seclabel,nosuid,nodev',
              :tmp_mount_fstype_dev_shm => 'tmpfs',
              :tmp_mount_path_dev_shm   => 'tmpfs',
          })}
          it { is_expected.to contain_mount('/dev/shm').with({
            :options => 'nodev,noexec,nosuid,rw,seclabel',
            :device  => 'tmpfs'
          })}
        end

      end
    end
  end
end
