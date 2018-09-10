# Add security settings to several mounts on the system.
#
# @param manage_tmp_perms
#   Ensure that  ``/tmp``, ``/var/tmp``, and ``/usr/tmp``, all have the proper
#   permissions and SELinux contexts.
#
# @param manage_proc
#   Manage the ``/proc`` mount on the system
#
# @param manage_sys
#   Manage the ``/sys`` mount on the system
#
# @param sys_options
#   The mountpoint options for ``/sys``
#
# @param manage_dev_pts
#   Manage the ``/dev/pts`` mount on the system
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::mountpoints (
  Boolean       $manage_tmp_perms = true,
  Boolean       $manage_sys       = true,
  Array[String] $sys_options      = ['rw','nodev','noexec'],
  Boolean       $manage_dev_pts   = true,
  Boolean       $manage_proc      = true
) {

  simplib::assert_metadata( $module_name )

  if $manage_tmp_perms { include '::simp::mountpoints::tmp' }
  if $manage_proc { include '::simp::mountpoints::proc' }


  if versioncmp($facts['os']['release']['major'],'6') == 0 {
    include '::simp::mountpoints::el6_tmp_fix'
  }

  if $manage_dev_pts {
    mount { '/dev/pts':
      ensure   => 'mounted',
      device   => 'devpts',
      fstype   => 'devpts',
      options  => 'rw,gid=5,mode=620,noexec',
      dump     => 0,
      pass     => 0,
      target   => '/etc/fstab',
      remounts => true
    }
  }
  if $manage_sys {
    mount { '/sys':
      ensure   => 'mounted',
      device   => 'sysfs',
      fstype   => 'sysfs',
      options  => join($sys_options,','),
      pass     => 0,
      target   => '/etc/fstab',
      remounts => true
    }
  }
}
