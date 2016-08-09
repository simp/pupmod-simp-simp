# == Class: simp::nfs::export_home
#
# Define to configure an NFS server to share centralized home directories in
# the NFSv4 way.
#
# This should work in most cases but, as with any 'stock' class/define, please
# feel free to simply use this as a reference if desired.
#
# It sets up the export root at ${data_dir}/nfs/exports and then adds
# ${data_dir}/nfs/home and submounts it under ${data_dir}/nfs/exports.
# This means that you can mount it as
# $nfs_server:/home from your clients.
#
# == Hiera Variables
#
# The following variables are required for this to function properly.
#
# === Server Variables
#
# The NFS server must set the following:
#   * nfs::server::conf::client_ips => An array of IPs/hosts to allow
#   * nfs::is_server : true
#
# === Client Variables
#
# The NFS clients must set the following:
#   * nfs::client::conf::nfs_server : 'hostname_of_the_nfs_server'
#
# == Parameters
#
# [*data_dir*]
#   Type: Absolute Path
#   Default: versioncmp(simp_version(),'5') ? { '-1' => '/srv', default => '/var' }
#
# [*client_nets*]
#   The networks that are allowed to mount this space.
#
# [*sec*]
#   An Array of sec modes for the export.
#
# [*create_home_dirs*]
#   Whether or not to automatically create user home directories
#   from LDAP data.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
# * Kendall Moore <kmoore@keywcorp.com>
#
class simp::nfs::export_home (
  $data_dir = versioncmp(simp_version(),'5') ? { '-1' => '/srv', default => '/var' },
  $client_nets = defined('$::client_nets') ? { true  => $::client_nets, default =>  hiera('client_nets') },
  $sec = ['sys'],
  $create_home_dirs = false
) {
  validate_net_list($client_nets)
  validate_bool($create_home_dirs)

  compliance_map()

  include '::nfs'
  include '::nfs::idmapd'

  # NOTE: You must set nfs::server::client_ips in hiera for this to function properly.
  include '::nfs::server'

  if $create_home_dirs {
    include '::simp::nfs::create_home_dirs'
  }

  if ! $::nfs::use_stunnel {
    nfs::server::export { 'nfs4_root':
      client      => nets2cidr($client_nets),
      export_path => "${data_dir}/nfs/exports",
      sec         => $sec,
      fsid        => '0',
      crossmnt    => true
    }

    nfs::server::export { 'home_dirs':
      client      => nets2cidr($client_nets),
      export_path => "${data_dir}/nfs/exports/home",
      rw          => true,
      sec         => $sec
    }
  }
  else {
    nfs::server::export { 'nfs4_root':
      client      => ['127.0.0.1'],
      export_path => "${data_dir}/nfs/exports",
      sec         => $sec,
      fsid        => '0',
      crossmnt    => true,
      insecure    => true
    }

    nfs::server::export { 'home_dirs':
      client      => ['127.0.0.1'],
      export_path => "${data_dir}/nfs/exports/home",
      rw          => true,
      sec         => $sec,
      insecure    => true
    }
  }

  file {
    [ "${data_dir}/nfs",
      "${data_dir}/nfs/exports",
      "${data_dir}/nfs/exports/home",
      "${data_dir}/nfs/home"
    ]:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    before => $create_home_dirs ? { true => Class['simp::nfs::create_home_dirs'], default => undef }
  }

  mount { "${data_dir}/nfs/exports/home":
    ensure   => 'mounted',
    fstype   => 'none',
    device   => "${data_dir}/nfs/home",
    remounts => true,
    options  => 'rw,bind',
    require  => [
      File["${data_dir}/nfs/exports/home"],
      File["${data_dir}/nfs/home"]
    ]
  }
}
