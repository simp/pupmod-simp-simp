# This class adds security settings to several mounts on the system.
#
# @param secure_tmp_mounts Boolean
#   If set to true>:
#   * Set noexec,nosuid,nodev on temp directories as appropriate and bind mount
#     /var/tmp to /tmp.
#   * If /tmp is *not* a separate partition, then it will be bind mounted to
#     itself with the modified settings.
#   If set to <tt>false</tt>:
#   * Do not manage the temp directories.
#
#   NOTE: If you have previously secured these directories, setting this to
#   'false' will *not* set them to any particular other mode. This is because
#   there is no way to know why you are changing these settings or what,
#   exactly, you want them to be.
#
# @param tmp_opts Array
#   If secure_tmp_mount is true, add these mount options to the /tmp
#   directory. If set to an empty array, it will simply preserve the
#   options that are currently in place.
#
#   Any 'no*' options will override their more permissive
#   counterparts that are currently set on the system.
#
#   See man mount(8) for a list of options.
#
# @param var_tmp_opts Array
#   Works the same way as *tmp_opts* above.
#
# @param dev_shm_opts Array
#   Works the same way as *tmp_opts* above.
#
# @params manage_tmp_perms Boolean
#   Ensure that  /tmp, /var/tmp, and /usr/tmp, all have the proper
#   permissions and SELinux contexts.
#
# @params manage_proc Boolean
#   If set, manage the /proc mount on the system
#
# @params proc_hidepid Integer[0,2]
#   0: This is the default setting and gives you the default
#   behaviour.
#
#   1: With this option an normal user would not see other processes
#   but their own about ps, top etc, but he is still able to see
#   process IDs in /proc
#
#   2 (default): Users are only able too see their own processes (like
#   with hidepid=1), but also the other process IDs are hidden for
#   them in /proc!
#
#   This option has no effect if ``$manage_proc`` is not ``true``
#
# @params proc_gid String
#   If set, this group will be able to see all processes on the system
#   regardless of the ``$proc_hidepid`` setting.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::mountpoints (
  Boolean $secure_tmp_mounts = true,
  Array $tmp_opts            = ['noexec','nodev','nosuid'],
  Array $var_tmp_opts        = ['noexec','nodev','nosuid'],
  Array $dev_shm_opts        = ['noexec','nodev','nosuid'],
  Boolean $manage_tmp_perms  = true,
  Boolean $manage_proc       = true,
  Integer[0,2] $proc_hidepid = 2,
  String $proc_gid           = ''
) {

  # Set some basic mounts (may be RHEL specific...)
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

  mount { '/sys':
    ensure   => 'mounted',
    device   => 'sysfs',
    fstype   => 'sysfs',
    options  => 'rw,nodev,noexec',
    pass     => '0',
    target   => '/etc/fstab',
    remounts => true
  }

  # If we decide to secure the tmp mounts....
  if $secure_tmp_mounts {
    # If /tmp is mounted
    if getvar('::tmp_mount_tmp') and !empty($::tmp_mount_tmp) {
      $tmp_mount_tmp_opts = split($::tmp_mount_tmp,',')

      # If /tmp is not a bind mount and doesn't contain the required options
      # then mount it properly.
      if !array_include($tmp_mount_tmp_opts,'bind') {
        mount { '/tmp':
          ensure   => 'mounted',
          target   => '/etc/fstab',
          fstype   => $::tmp_mount_fstype_tmp,
          options  => join_mount_opts($tmp_mount_tmp_opts,$tmp_opts),
          device   => $::tmp_mount_path_tmp,
          pass     => '1',
          remounts => true
        }
      }
      else {
        mount { '/tmp':
          ensure   => 'mounted',
          target   => '/etc/fstab',
          fstype   => 'none',
          options  => join_mount_opts(['bind'],$tmp_opts),
          device   => $::tmp_mount_path_tmp,
          remounts => true
        }

        if !empty(difference($tmp_opts,$tmp_mount_tmp_opts)) {
          $_remount_tmp_opts = join($tmp_opts,',')

          exec { 'remount /tmp':
            command => "/bin/mount -o remount,${_remount_tmp_opts} /tmp",
            require => Mount['/tmp']
          }
        }
      }
    }
    # Otherwise, bind mount it to itself with the correct options.
    # We thought about mounting it to tmpfs but that was just too dangerous
    # without knowing the target environment.
    else {
      mount { '/tmp':
        ensure   => 'mounted',
        target   => '/etc/fstab',
        fstype   => 'none',
        options  => join_mount_opts(['bind'],$tmp_opts),
        device   => '/tmp',
        remounts => true,
        notify   => Exec['remount /tmp']
      }

      exec { 'remount /tmp':
        command     => "/bin/mount -o remount,${tmp_opts} /tmp",
        refreshonly => true
      }
    }

    if (defined('$::simplib::manage_tmp_perms') and
        getvar('::simplib::manage_tmp_perms') and
        getvar('::tmp_mount_tmp')) {
      File['/tmp'] -> Mount['/tmp']
    }

    # If /var/tmp is mounted
    if getvar('::tmp_mount_var_tmp') and !empty($::tmp_mount_var_tmp) {
      $tmp_mount_var_tmp_opts = split($::tmp_mount_var_tmp,',')

      # If /var/tmp is not a bind mount then mount it properly.
      if !array_include($tmp_mount_var_tmp_opts,'bind') {
        mount { '/var/tmp':
          ensure   => 'mounted',
          target   => '/etc/fstab',
          fstype   => $::tmp_mount_fstype_var_tmp,
          options  => join_mount_opts($tmp_mount_var_tmp_opts,$var_tmp_opts),
          device   => $::tmp_mount_path_var_tmp,
          pass     => '1',
          remounts => true
        }
      }
      else {
        mount { '/var/tmp':
          ensure   => 'mounted',
          target   => '/etc/fstab',
          fstype   => 'none',
          options  => join_mount_opts(['bind'],$var_tmp_opts),
          device   => $::tmp_mount_path_var_tmp,
          remounts => true
        }

        if !empty(difference($var_tmp_opts,$tmp_mount_var_tmp_opts)) {
          $_remount_var_tmp_opts = join($var_tmp_opts,',')

          exec { 'remount /var/tmp':
            command => "/bin/mount -o remount,${_remount_var_tmp_opts} /var/tmp",
            require => Mount['/var/tmp']
          }
        }
      }
    }
    # Otherwise, bind mount it to /tmp.
    else {
      mount { '/var/tmp':
        ensure   => 'mounted',
        device   => '/tmp',
        fstype   => 'none',
        options  => join_mount_opts(['bind'],$var_tmp_opts),
        target   => '/etc/fstab',
        remounts => true,
        notify   => Exec['remount /var/tmp']
      }

      exec { 'remount /var/tmp':
        command     => "/bin/mount -o remount,${var_tmp_opts} /var/tmp",
        refreshonly => true
      }
    }

    if (defined('$::simplib::manage_tmp_perms') and
        getvar('::simplib::manage_tmp_perms')  and
        getvar('::tmp_mount_var_tmp')) {
      File['/var/tmp'] -> Mount['/var/tmp']
    }

    # If /dev/shm is mounted
    if getvar('::tmp_mount_dev_shm') and !empty($::tmp_mount_dev_shm) {
      $tmp_mount_dev_shm_opts = split($::tmp_mount_dev_shm,',')

      # If /dev/shm doesn't contain the required options then mount it
      # properly.
      mount { '/dev/shm':
        ensure   => 'mounted',
        options  => join_mount_opts($tmp_mount_dev_shm_opts,$dev_shm_opts),
        device   => $::tmp_mount_path_dev_shm,
        fstype   => 'tmpfs',
        target   => '/etc/fstab',
        remounts => true
      }
    }

    if $::operatingsystem in ['RedHat','CentOS'] and (versioncmp($::operatingsystemmajrelease,'6') == 0) {
      include '::upstart'

      # There is a bizarre bug where /tmp and /var/tmp will have incorrect
      # permissions after the *second* reboot after bootstrapping SIMP. This
      # upstart job is an effective, but kludgy, way to remedy this issue. We
      # have not been able to repeat the issue reliably enough in a
      # controlled environment to determine the root cause.
      upstart::job { 'fix_tmp_perms':
        main_process_type => 'script',
        main_process      => '
perm1=$(/usr/bin/find /tmp -maxdepth 0 -perm -ugo+rwxt | /usr/bin/wc -l)
perm2=$(/usr/bin/find /var/tmp -maxdepth 0 -perm -ugo+rwxt | /usr/bin/wc -l)

if [ "$perm1" != "1" ]; then
  /bin/chmod ugo+rwxt /tmp
fi

if [ "$perm2" != "1" ]; then
  /bin/chmod ugo+rwxt /var/tmp
fi
',
        start_on          => 'runlevel [0123456]',
        description       => 'Used to enforce /tmp and /var/tmp permissions to be 777.'
      }
    }
  }

    if $manage_tmp_perms {
      file { '/tmp':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => 'u+rwx,g+rwx,o+rwxt',
        force  => true
      }

      file { '/var/tmp':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => 'u+rwx,g+rwx,o+rwxt',
        force  => true
      }

      file { '/usr/tmp':
        ensure  => 'symlink',
        target  => '/var/tmp',
        force   => true,
        seltype => 'tmp_t',
        require => File['/var/tmp']
      }
    }

    if $manage_proc {
      if !empty($proc_gid) {
        $proc_options = "hidepid=${proc_hidepid},gid=${proc_gid}"
      }
      else {
        $proc_options = "hidepid=${proc_hidepid}"
      }
      mount { '/proc':
      ensure   => 'mounted',
      atboot   => true,
      device   => 'proc',
      fstype   => 'proc',
      remounts => true,
      options  => $proc_options
    }
  }
}
