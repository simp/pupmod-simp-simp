# This class adds security settings to several mounts on the system.
#
# @params manage_tmp_perms
#   Ensure that  /tmp, /var/tmp, and /usr/tmp, all have the proper
#   permissions and SELinux contexts.
#
# @params manage_proc
#   If set, manage the /proc mount on the system
#
# @params manage_sys
#   If set, manage the /sys mount on the system
#
# @params manage_dev_pts
#   If set, manage the /dev/pts mount on the system
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::mountpoints (
  Boolean $manage_sys       = true,
  Boolean $manage_tmp_perms = true,
  Boolean $manage_dev_pts   = true,
  Boolean $manage_proc      = true
) {

  # Set some basic mounts (may be RHEL specific...)
  if $manage_dev_pts {
    mount { '/dev/pts':
      ensure   => 'mounted',
      device   => 'devpts',
      fstype   => 'devpts',
      options  => 'rw,gid=5,mode=620,noexec',
      dump     => '0',
      pass     => '0',
      target   => '/etc/fstab',
      remounts => true
    }
  }
  if $manage_sys {
    mount { '/sys':
      ensure   => 'mounted',
      device   => 'sysfs',
      fstype   => 'sysfs',
      options  => 'rw,nodev,noexec',
      pass     => '0',
      target   => '/etc/fstab',
      remounts => true
    }
  }

  if $manage_tmp_perms {
    include '::simp::mountpoints::tmp'
  }

  if $manage_proc {
    include '::simp::mountpoints::proc'
  }

  if $::operatingsystem in ['RedHat','CentOS'] and (versioncmp($::operatingsystemmajrelease,'6') == 0) {
    include '::simp::mountpoints::el6_tmp_fix'
  }

}
