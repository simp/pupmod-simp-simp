# == Class: simp
#
# This class provides the basis of what a native SIMP system should
# be. It is expected that users may deviate from this configuration
# over time, but this should be an effective starting place.
#
# == Parameters
#
# [*is_mail_server*]
# Type: Boolean
# Default: true
#   If set to true, install a local mail service on the system. This
#   will not conflict with using the postfix class to turn the system
#   into a full server later on.
#
#   If the hiera variable 'mta' is set, and is this node, then this will turn
#   this node into an MTA instead of a local mail only server.
#
# [*rsync_stunnel*]
# Type: FQDN
# Default: hiera('rsync::stunnel',hiera('puppet::server'))
#   The rsync server from which files should be retrieved.
#
# [*is_rsyslog_server*]
# Type: Boolean
# Default: false
#   Whether or not this node is an Rsyslog server.
#   If true, will set up rsyslog::stock::log_server, otherwise will use
#   rsyslog::stock::log_shipper.
#
#   It is highly recommended that you use Logstash as your syslog server if at
#   all possible.
#
# [*use_nscd*]
# Type: Boolean
# Default: true
#   Whether or not to use NSCD in the installation instead of SSSD. If
#   '$use_sssd = true' then this will not be referenced.
#
# [*use_sssd*]
# Type: Boolean
# Default: false if EL<7, true otherwise
#   Whether or not to use SSSD in the installation.
#   There are issues where SSSD will allow a login, even if the user's password
#   has expire, if the user has a valid SSH key. However, in EL7+, there are
#   issues with nscd and nslcd which can lock users our of the system when
#   using LDAP.
#
# [*use_ssh_global_known_hosts*]
# Type: Boolean
# Default: false
#   If true, use the ssh_global_known_hosts function to gather the various host
#   SSH public keys and populate the /etc/ssh/known_hosts file.
#
# [*enable_filebucketing*]
# Type: Boolean
# Default: true
#   If true, enable the server-side filebucket for all managed files on the
#   client system.
#
# [*filebucket_server*]
# Type: FQDN
# Default: ''
#   Sets up a remote filebucket target if set.
#
# [*puppet_server*]
# Type: FQDN
# Default: ''
#   If set along with $puppet_server_ip, will be used to add an entry to
#   /etc/hosts that points to your Puppet server. This is recommended for DNS
#   servers in case you need Puppet to fix DNS for you.
#
# [*puppet_server_ip*]
# Type: IP Address
# Default: ''
#   See $puppet_server above.
#
# == Hiera Variables
#
# These variables are not necessarily used directly by this class but
# are quite useful in getting your system functioning easily.
#
# [*use_sssd*]
#   See above
#
# [*use_nscd*]
#   See above
#
# [*simplib::timezone*]
# Type: String
# Default: GMT
#   Set your system timezone.
#
# == Authors
#
# Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp (
  $is_mail_server = true,
  $rsync_stunnel = hiera('rsync::stunnel',hiera('puppet::server',''),''),
  $use_ldap = defined('$::use_ldap') ? { true => $::use_ldap, default => hiera('use_ldap',true) },
  $use_nscd = $::simp::params::use_nscd,
  $use_sssd = $::simp::params::use_sssd,
  $use_ssh_global_known_hosts = false,
  $use_stock_sssd = true,
  $enable_filebucketing = true,
  $filebucket_server = '',
  $puppet_server = defined('$::servername') ? { true => $::servername, default => hiera('puppet::server','') },
  $puppet_server_ip = ''
) inherits ::simp::params {

  if empty($rsync_stunnel) {
    if defined('$::servername') {
      $_rsync_stunnel = $::servername
    }
    else {
      $_rsync_stunnel = ''
    }
  }
  else {
    $_rsync_stunnel = $rsync_stunnel
  }


  validate_bool($is_mail_server)
  if !empty($_rsync_stunnel) { validate_net_list($_rsync_stunnel) }
  validate_bool($use_ldap)
  validate_bool($use_nscd)
  validate_bool($use_sssd)
  validate_bool($use_stock_sssd)
  validate_bool($enable_filebucketing)
  if !empty($filebucket_server) { validate_net_list($filebucket_server) }
  if !empty($puppet_server) { validate_net_list($puppet_server) }
  if !empty($puppet_server_ip) { validate_net_list($puppet_server_ip) }

  compliance_map()

  if !$enable_filebucketing {
    File { backup => false }
  }
  else {
    File { backup => true }
  }

  if !empty($filebucket_server) {
    filebucket { 'main': server => $filebucket_server }
  }

  if $is_mail_server {
    $l_mta = hiera('mta','')
    if !empty($l_mta) {
      include '::postfix::server'
    }
    else {
      include '::postfix'
    }
  }

  if $use_ldap {
    include '::openldap::pam'
    include '::openldap::client'
  }

  if $use_sssd {
    if $use_stock_sssd {
      include '::simp::sssd::client'
    }
  }
  else {
    if $use_nscd {
      include 'nscd'
      include 'nscd::passwd'
      include 'nscd::group'
      include 'nscd::services'
    }
  }

  if !empty($puppet_server_ip) and !empty($puppet_server) {
    validate_net_list($puppet_server_ip)

    $l_pserver_alias = split($puppet_server,'.')

    host { $puppet_server:
      ensure       => 'present',
      host_aliases => $l_pserver_alias[0],
      ip           => $puppet_server_ip
    }
  }

  file { '/etc/simp':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/etc/simp/simp.version':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => simp_version()
  }

  if $use_ssh_global_known_hosts {
    ssh_global_known_hosts()
    sshkey_prune { '/etc/ssh/ssh_known_hosts': }
  }

  if !empty($_rsync_stunnel) and !host_is_me($_rsync_stunnel) {
    # Add an stunnel client entry for rsync.
    stunnel::add { 'rsync':
      connect => ["${_rsync_stunnel}:8730"],
      accept  => '127.0.0.1:873'
    }
  }
}
