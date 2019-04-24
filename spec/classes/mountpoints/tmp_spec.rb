require 'spec_helper'

describe 'simp::mountpoints::tmp' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          if os_facts[:init_systems].include?('systemd')
            os_facts.merge({
              # This replicates a normal EL7 default installation
              :tmp_mount_fstype_tmp => 'tmpfs'
            })
          else
            os_facts
          end
        end

        shared_examples_for 'a legacy system' do
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
            let(:facts) do os_facts.merge({
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
        end

        if os_facts[:init_systems].include?('systemd')
          context 'with default parameters' do
            it { is_expected.to_not create_file('/tmp') }
            it { is_expected.to create_file('/var/tmp').with_mode('u+rwx,g+rwx,o+rwxt') }
            it { is_expected.to create_file('/usr/tmp').with_ensure('symlink') }
            it { is_expected.to_not create_service('tmp.mounts').with_ensure('running') }
            it { is_expected.to_not create_service('tmp.mounts').with_enable(true) }
            it { is_expected.to contain_systemd__unit_file('tmp.mount').with_enable(true) }
            it { is_expected.to contain_systemd__unit_file('tmp.mount').with_active(true) }
            it {
              is_expected.to contain_systemd__unit_file('tmp.mount').
                with_content(
                  <<-EOM
[Mount]
What=tmpfs
Where=/tmp
Type=tmpfs
Options=mode=1777,nodev,noexec,nosuid
                  EOM
                )
            }
          end

          context 'tmp_is_partition' do
            let(:facts) do os_facts.merge({
                :tmp_mount_tmp        => 'rw,seclabel,relatime,data=ordered',
                :tmp_mount_fstype_tmp => 'ext4',
                :tmp_mount_path_tmp   => '/dev/sda3',
              })
            end

            it { is_expected.to contain_mount('/tmp').with({
              :options => 'data=ordered,nodev,noexec,nosuid,relatime,rw,seclabel',
              :device  => '/dev/sda3'
            })}

            it { is_expected.to_not contain_systemd__unit_file('tmp.mount') }
          end

          context 'tmp_service == false' do
            let(:params) {{
              :tmp_service => false
            }}

            it_behaves_like 'a legacy system'
          end
        else
          it_behaves_like 'a legacy system'
        end

        context 'var_tmp_is_partition' do
          let(:facts) { os_facts.merge({
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
          let(:facts) { os_facts.merge({
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
          let(:facts) { os_facts.merge({
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
