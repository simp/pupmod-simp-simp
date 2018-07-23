require 'spec_helper_acceptance'

test_name 'Secure Mountpoints'

describe 'simplib::secure_mountpoints class' do
  let(:manifest) {
    <<-EOS
      class { 'simp::mountpoints': }
    EOS
  }

  let(:tmp_dirs) {
    [ '/tmp', '/var/tmp', '/dev/shm' ]
  }

  hosts.each do |host|
    context 'default parameters' do
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)

        # Unfortunately...it has to run twice because /dev/shm has a relatime
        # value that doesn't seem to be present on the initial run.
        # FIXME: Figure out what's going on here...

        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should prevent running applications in the noexec mounts' do
        tmp_dirs.each do |dir|
          on(host,%(cp /bin/ls #{dir}))

          on(host, %(#{dir}/ls), :acceptable_exit_codes => [126])
        end

      end

      it 'should prevent the creation of devices in the nodev mounts' do
        tmp_dirs.each do |dir|
          on(host,%(mknod #{dir}/test_null c 1 3)) unless host.file_exist?(%(#{dir}/test_null))

          on(host, %(echo 'test' > /#{dir}/test_null), :acceptable_exit_codes => [1])
        end

      end

      it 'should not allow the creation of files using suid abiliities' do
        tmp_dirs.each do |dir|
          # Need something to execute
          on(host,%(install -m 4755 /bin/touch #{dir}/touch_test))
          # Need to be able to execute it
          on(host,%(mount -o remount,exec #{dir}))
          # Need a user other than root to execute the file
          on(host,%(puppet resource user touch_test_user ensure=present))
          # Need to be able to use 'su'
          on(host,%(sed -i 's/^-:/+:/g' /etc/security/access.conf))
          # Touch a file!
          on(host,%(su touch_test_user -c '#{dir}/touch_test #{dir}/touch_test_output'))
          # Check the permissions
          expect(
            on(host,%(stat -c "%U" #{dir}/touch_test_output)).output.strip
          ).to eq('touch_test_user')

          # Clean up after ourselves....
          on(host,%(mount -o remount #{dir}))
        end
      end
    end
  end
end
