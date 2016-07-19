# == Class: simp::nfs::home_client
#
# Set up an NFS4 client to point to the server that you defined with
# nfs::stock::export_home.
#
# == Parameters
#
# [*nfs_server*]
#   The NFS server to which you will be connecting.
#
# [*port*]
#   The NFS port to which to connect.
#
# [*sec*]
#   The sec mode for the mount.
#
# [*use_autofs*]
#   Whether or not to use autofs. Defaults to true for the benefits of
#   autofs.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class simp::nfs::home_client (
  $nfs_server = defined('$::nfs_server') ? { true => $::nfs_server, default => hiera('nfs::server') },
  $port = '2049',
  $sec = 'sys',
  $use_autofs = true
) {

  validate_bool($use_autofs)
  validate_port($port)

  include '::nfs'
  include '::nfs::idmapd'

  $_it_is_me = host_is_me($nfs_server)

  if $_it_is_me {
    $_target = '127.0.0.1'
  }
  else {
    $_target = $nfs_server

    if defined('$::selinux_current_mode') and getvar('::selinux_current_mode') != 'disabled' {
      selboolean { 'use_nfs_home_dirs':
        persistent => true,
        value      => 'on'
      }
    }
  }

  # NOTE:
  # nfs::client::nfs_server must be set in hiera for this to function properly.
  include '::nfs::client'

  if $use_autofs {
    include '::autofs'

    autofs::map::master { 'home':
      mount_point => '/home',
      map_name    => '/etc/autofs/home.map'
    }

    if (! $::nfs::use_stunnel) or $_it_is_me {
      autofs::map::entry { 'wildcard':
        options  => "-fstype=nfs4,port=${port},hard,intr,sec=${sec}",
        location => "${_target}:/home/&",
        target   => 'home'
      }
    }
    else {
      autofs::map::entry { 'wildcard':
        options  => "-fstype=nfs4,port=${port},hard,intr,sec=${sec}",
        location => '127.0.0.1:/home/&',
        target   => 'home'
      }
    }
  }
  else {
    if (! $::nfs::use_stunnel) or $_it_is_me {
      mount { '/home':
        ensure   => 'mounted',
        atboot   => true,
        device   => "${_target}:/home",
        fstype   => 'nfs4',
        options  => "sec=${sec},port=${port},hard,intr",
        remounts => false
      }
    }
    else {
      mount { '/home':
        ensure   => 'mounted',
        atboot   => true,
        device   => '127.0.0.1:/home',
        fstype   => 'nfs4',
        options  => "sec=${sec},port=${port},hard,intr",
        remounts => false
      }
    }
  }
}
