# Adds a script to create user home directories for directory server
# by pulling users from LDAP
#
# @param uri
#   The uri of the LDAP servers, specified as space-separated list
#
# @param user_ou
#   The OU under which users are stored.
#
# @param export_dir
#   The location of the home directories being exported.
#   This location will have to have a puppet managed File resource
#   associated.  See the nfs::stock::export_home class for an example
#
# @param skel_dir
#   The location of sample skeleton files for user directories.
#   By default this is /etc/skel which is not managed by Puppet,
#   therefore, no required File resource here
#
# @param ldap_scope
#   The search scope to use.
#   Valid options are 'one', 'sub', and 'base'.
#   Defaults to 'base' if an invalid option is specified.
#
# @param bind_dn
#   The DN to use when binding to the LDAP server
#
# @param bind_pw
#   The password to use when binding to the LDAP server
#
# @param port
#   The target port on the LDAP server.  If none specified,
#   defaults to 389 for non-TLS/start_tls connections, and
#   636 for SSL connections.
#
#   Default: $simp::nfs::params::port
#
# @param tls
#   Whether or not to enable SSL/TLS for the connection.
#   $tls = 'ssl'         -> LDAPS on port 636, unless  different *port* specified.
#                           Uses simple_tls; No validation of the LDAP server's SSL
#                           certificate is performed.
#   $tls = 'start_tls'   -> Start TLS on port 389, unless different *port* specified.
#   $tls = 'none'        -> LDAP on port 389, unless different *port* specified.
#                           No Encryption.
#
#   Default: $simp::nfs::params::tls
#
# @param quiet
#   Whether or not to print potentially useful warnings
#
# @param syslog_facility
#   The syslog facility at which to log, must be Ruby 'syslog' compatible.
#
# @param syslog_priority
#   The syslog priority at which to log, must be Ruby 'syslog' compatible.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::nfs::create_home_dirs (
  Variant[String,Array[String]]  $uri             = hiera('ldap::uri'),
  String                         $base_dn         = hiera('ldap::base_dn'),
  Stdlib::Absolutepath           $export_dir      = '/var/nfs/home',
  Stdlib::Absolutepath           $skel_dir        = '/etc/skel',
  Enum['one','sub','base']       $ldap_scope      = 'one',
  String                         $bind_dn         = hiera('ldap::bind_dn'),
  String                         $bind_pw         = hiera('ldap::bind_pw'),
  String                         $port            = $simp::nfs::params::port,
  Enum['ssl','start_tls','none'] $tls             = $simp::nfs::params::tls,
  Boolean                        $quiet           = true,
  String                         $syslog_facility = 'LOG_LOCAL6',
  String                         $syslog_priority = 'LOG_NOTICE',
) inherits simp::nfs::params {
  assert_private()

  package { 'rubygem-net-ldap':
    ensure => 'latest'
  }

  file { '/etc/cron.hourly/create_home_directories.rb':
    owner   => 'root',
    group   => 'root',
    mode    => '0500',
    content => template('simp/create_home_directories.rb.erb'),
    notify  => [ Exec['/etc/cron.hourly/create_home_directories.rb'] ],
    require => Package['rubygem-net-ldap'],
  }

  exec { '/etc/cron.hourly/create_home_directories.rb':
    refreshonly => true,
  }
}
