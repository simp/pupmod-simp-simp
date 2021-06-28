# @summary Manages the various tmp mounts with optional security features.
#
# @see mount(8)
#
# @param secure
#   * Set ``noexec,nosuid,nodev`` on temp directories as appropriate and bind
#     mount ``/var/tmp`` to ``/tmp``
#   * If ``/tmp`` is *not* a separate partition, then it will be bind mounted
#     to itself with the modified settings
#
#   * **NOTE:** If you have previously secured these directories, setting this
#     to ``false`` will **not** set them to any particular other mode. This is
#     because there is no way to know why you are changing these settings or
#     what, exactly, you want them to be.
#
# @param tmp_opts
#   If ``$secure`` is ``true``, add these mount options to the ``/tmp``
#   directory
#
#   * If set to an empty Array, it will simply preserve the options that are
#     currently in place
#   * Any ``no*`` options will override their more permissive counterparts that
#     are currently set on the system
#
# @param var_tmp_opts
#   Works the same way as ``$tmp_opts``
#
# @param dev_shm_opts
#   Works the same way as ``$tmp_opts``
#
# @param tmp_service
#   If on systemd system, enable and activate the tmp.mount service
#
#   * Note: If you set this to `true` on a system that does not already have
#     the `tmp.mounts` service running, you may find that the service cannot
#     start due to processes locking files in the existing `/tmp` directory. If
#     this occurs, you can run `lsof /tmp` to determine what is locking. You
#     will probably need to reboot your system to start with a properly clean
#     `/tmp` mount.
#
# @author https://github.com/simp/pupmod-simp-simp/graphs/contributors
class simp::mountpoints::tmp (
  Boolean       $secure       = true,
  Array[String] $tmp_opts     = ['noexec','nodev','nosuid'],
  Array[String] $var_tmp_opts = ['noexec','nodev','nosuid'],
  Array[String] $dev_shm_opts = ['noexec','nodev','nosuid'],
  Boolean       $tmp_service  = (fact('tmp_mount_fstype_tmp') == 'tmpfs') ? { true => true, default => false }
) {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  unless $tmp_service {
    # Do not manage this if systemd is supposed to manage it

    file { '/tmp':
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => 'u+rwx,g+rwx,o+rwxt',
      seltype => 'tmp_t',
      force   => true
    }
  }

  file { '/var/tmp':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => 'u+rwx,g+rwx,o+rwxt',
    seltype => 'tmp_t',
    force   => true
  }

  file { '/usr/tmp':
    ensure  => 'symlink',
    target  => '/var/tmp',
    force   => true,
    seltype => 'tmp_t',
    require => File['/var/tmp']
  }

  # If we decide to secure the tmp mounts....
  if $secure {
    if $tmp_service {
      # Systemd adds appropriate extra sets of options and is authoritative so
      # everything should be set via $tmp_opts instead of reverse mapped like
      # we do if it's a regular partition.
      $_tmp_opts = simplib::join_mount_opts($tmp_opts, ['mode=1777'])

      $_unit_file_content = @("END")
        [Mount]
        What=tmpfs
        Where=/tmp
        Type=tmpfs
        Options=${_tmp_opts}
        | END

      systemd::unit_file { 'tmp.mount':
        enable  => true,
        active  => true,
        content => $_unit_file_content
      }
    }
    else {
      # If /tmp is mounted
      if $facts['tmp_mount_tmp'] and !empty($facts['tmp_mount_tmp']) {
        $_tmp_mount_tmp_opts = split($facts['tmp_mount_tmp'],',')

        # If /tmp is not a bind mount and doesn't contain the required options
        # then mount it properly.
        if !member($_tmp_mount_tmp_opts,'bind') {
          mount { '/tmp':
            ensure   => 'mounted',
            target   => '/etc/fstab',
            fstype   => $facts['tmp_mount_fstype_tmp'],
            options  => simplib::join_mount_opts($_tmp_mount_tmp_opts,$tmp_opts),
            device   => $facts['tmp_mount_path_tmp'],
            pass     => '1',
            remounts => true
          }
        }
        else {
          mount { '/tmp':
            ensure   => 'mounted',
            target   => '/etc/fstab',
            fstype   => 'none',
            options  => simplib::join_mount_opts(['bind'],$tmp_opts),
            device   => $facts['tmp_mount_path_tmp'],
            remounts => true,
            notify   => Exec['remount /tmp']
          }

          $_remount_tmp_opts = join($tmp_opts,',')
          exec { 'remount /tmp':
            command     => "/bin/mount -o remount,${_remount_tmp_opts} /tmp",
            refreshonly => true
          }
        }
      }
      else {
        mount { '/tmp':
          ensure   => 'mounted',
          target   => '/etc/fstab',
          fstype   => 'none',
          options  => simplib::join_mount_opts(['bind'],$tmp_opts),
          device   => '/tmp',
          remounts => true,
          notify   => Exec['remount /tmp']
        }

        $_remount_tmp_opts = join($tmp_opts,',')
        exec { 'remount /tmp':
          command     => "/bin/mount -o remount,${_remount_tmp_opts} /tmp",
          refreshonly => true
        }
      }

      File['/tmp'] -> Mount['/tmp']
    }

    # If /var/tmp is mounted
    if $facts['tmp_mount_var_tmp'] and !empty($facts['tmp_mount_var_tmp']) {
      $_tmp_mount_var_tmp_opts = split($facts['tmp_mount_var_tmp'],',')

      # If /var/tmp is not a bind mount then mount it properly.
      if !member($_tmp_mount_var_tmp_opts,'bind') {
        mount { '/var/tmp':
          ensure   => 'mounted',
          target   => '/etc/fstab',
          fstype   => $facts['tmp_mount_fstype_var_tmp'],
          options  => simplib::join_mount_opts($_tmp_mount_var_tmp_opts,$var_tmp_opts),
          device   => $facts['tmp_mount_path_var_tmp'],
          pass     => '1',
          remounts => true
        }
      }
      else {
        mount { '/var/tmp':
          ensure   => 'mounted',
          target   => '/etc/fstab',
          fstype   => 'none',
          options  => simplib::join_mount_opts(['bind'],$var_tmp_opts),
          device   => $facts['tmp_mount_path_var_tmp'],
          remounts => true
        }

        if !empty(difference($var_tmp_opts,$_tmp_mount_var_tmp_opts)) {
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
        options  => simplib::join_mount_opts(['bind'],$var_tmp_opts),
        target   => '/etc/fstab',
        remounts => true,
        notify   => Exec['remount /var/tmp']
      }

      $_remount_var_tmp_opts = join($var_tmp_opts,',')
      exec { 'remount /var/tmp':
        command     => "/bin/mount -o remount,${_remount_var_tmp_opts} /var/tmp",
        refreshonly => true
      }
    }

    File['/var/tmp'] -> Mount['/var/tmp']

    # If /dev/shm is mounted
    if $facts['tmp_mount_dev_shm'] and !empty($facts['tmp_mount_dev_shm']) {
      $_tmp_mount_dev_shm_opts = split($facts['tmp_mount_dev_shm'],',')

      # If /dev/shm doesn't contain the required options then mount it
      # properly.
      mount { '/dev/shm':
        ensure   => 'mounted',
        options  => simplib::join_mount_opts($_tmp_mount_dev_shm_opts,$dev_shm_opts),
        device   => $facts['tmp_mount_path_dev_shm'],
        fstype   => 'tmpfs',
        target   => '/etc/fstab',
        remounts => true
      }
    }
  }

  # This is a kludge at the end based on the fact that the 'if secure' code up
  # above would be far too complex to understand easily if this were woven in.
  #
  # Specifically, this meets the requirement to start the tmp.mount service but
  # understands that the ``systemd::unit_file`` resource above will also
  # attempt to manage the tmp.mount service.
  if $tmp_service {
    unless defined(Systemd::Unit_file['tmp.mount']) {
      ensure_resources('service', { 'tmp.mount' => { 'ensure' => 'running', 'enable' => true }})
    }
  }
}
