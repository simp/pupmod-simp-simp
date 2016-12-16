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
# @param data_dir
#
# @param trusted_nets
#   The networks that are allowed to mount this space.
#
# @param sec
#   An Array of sec modes for the export.
#
# @param create_home_dirs
#   Whether or not to automatically create user home directories
#   from LDAP data.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
# @author Kendall Moore <kmoore@keywcorp.com>
#
class simp::nfs::export_home (
  Stdlib::Absolutepath  $data_dir         = '/var',
  Array[String]         $trusted_nets     = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1','::1'] }),
  Array[String]         $sec              = ['sys'],
  Boolean               $create_home_dirs = false
) {
  validate_net_list($trusted_nets)

  include '::nfs'
  include '::nfs::idmapd'

  # NOTE: You must set nfs::server::client_ips in hiera for this to function properly.
  include '::nfs::server'

  if $create_home_dirs {
    include '::simp::nfs::create_home_dirs'
  }

  if ! $::nfs::use_stunnel {
    nfs::server::export { 'nfs4_root':
      client      => nets2cidr($trusted_nets),
      export_path => "${data_dir}/nfs/exports",
      sec         => $sec,
      fsid        => '0',
      crossmnt    => true
    }

    nfs::server::export { 'home_dirs':
      client      => nets2cidr($trusted_nets),
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

  $_create_home_dirs = $create_home_dirs ? {
    true => Class['simp::nfs::create_home_dirs'],
    default => undef
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
    before => $_create_home_dirs
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
