# This class provides the basis of what a native SIMP system should
# be. It is expected that users may deviate from this configuration
# over time, but this should be an effective starting place.
#
# @param is_mail_server Boolean
#   If set to true, install a local mail service on the system. This
#   will not conflict with using the postfix class to turn the system
#   into a full server later on.
#
#   If the hiera variable 'mta' is set, and is this node, then this will turn
#   this node into an MTA instead of a local mail only server.
#
# @param rsync_stunnel
# Type: FQDN
#   The rsync server from which files should be retrieved.
#
# @param is_rsyslog_server Boolean
#   Whether or not this node is an Rsyslog server.
#   If true, will set up rsyslog::stock::log_server, otherwise will use
#   rsyslog::stock::log_shipper.
#
#   It is highly recommended that you use Logstash as your syslog server if at
#   all possible.
#
# @param use_nscd Boolean
#   Whether or not to use NSCD in the installation instead of SSSD. If
#   '$use_sssd = true' then this will not be referenced.
#
# @param use_sssd Boolean
#   Whether or not to use SSSD in the installation.
#   There are issues where SSSD will allow a login, even if the user's password
#   has expire, if the user has a valid SSH key. However, in EL7+, there are
#   issues with nscd and nslcd which can lock users our of the system when
#   using LDAP.
#
# @param use_ssh_global_known_hosts Boolean
#   If true, use the ssh_global_known_hosts function to gather the various host
#   SSH public keys and populate the /etc/ssh/known_hosts file.
#
# @param version_info Boolean
#   Drops SIMP and SIMP-version related information to the filesystem.
#
# @param manage_root_metadata Boolean
#   Include the simp::root_user class, which manages resources related to the root user.
#
# @param enable_filebucketing Boolean
#   If true, enable the server-side filebucket for all managed files on the
#   client system.
#
# @param filebucket_server
#   Type: FQDN
#   Sets up a remote filebucket target if set.
#
# @param puppet_server
#   Type: FQDN
#   If set along with $puppet_server_ip, will be used to add an entry to
#   /etc/hosts that points to your Puppet server. This is recommended for DNS
#   servers in case you need Puppet to fix DNS for you.
#
# @param puppet_server_ip
#   Type: IP Address
#   See $puppet_server above.
#
# @params use_sudoers_aliases Boolean
#   If true, enable simp site sudoers aliases.
#
# @params runlevel String
#   Expects: 1-5, rescue, multi-user, or graphical
#   The default runlevel to which the system should be set.
#
# @params max_logins Integer
#   The number of logins that an account may have on the system at a given time
#   as enforced by PAM. Set to undef to disable.
#
#   As set, meets CCE-27457-1
#
# @params manage_root_perms Boolean
#   Ensure that /root has restricted permissions and proper SELinux
#   contexts.
#
# @params disable_rc_local Boolean
#   If true, disable the use of the /etc/rc.local file.
#
# @params dns_autoconf Boolean
#   If true, autoconfigure named if the dns::servers include the host.
#
# == Hiera Variables
#
# These variables are not necessarily used directly by this class but
# are quite useful in getting your system functioning easily.
#
# @param use_sssd
#   See above
#
# @param use_nscd
#   See above
#
# @param simplib::timezone
# Default: GMT
#   Set your system timezone.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp (
  Boolean                 $is_mail_server             = true,
  String                  $rsync_stunnel              = hiera('rsync::stunnel',hiera('puppet::server',''),''),
  Boolean                 $use_fips                   = defined('$::use_fips') ? { true => $::use_fips, default => hiera('use_fips',false) },
  Boolean                 $use_ldap                   = defined('$::use_ldap') ? { true => $::use_ldap, default => hiera('use_ldap',true) },
  Boolean                 $use_nscd                   = $::simp::params::use_nscd,
  Boolean                 $use_sssd                   = $::simp::params::use_sssd,
  Boolean                 $use_ssh_global_known_hosts = false,
  Boolean                 $use_stock_sssd             = true,
  Boolean                 $version_info               = true,
  Boolean                 $manage_root_metadata       = true,
  Boolean                 $enable_filebucketing       = true,
  Optional[Array[String]] $filebucket_server          = undef,
  String                  $puppet_server              = defined('$::servername') ? { true => $::servername, default => hiera('puppet::server','') },
  Optional[String]        $puppet_server_ip           = undef,
  Boolean                 $use_sudoers_aliases        = true,
  String                  $runlevel                   = '3',
  String                  $max_logins                 = '10',
  Boolean                 $manage_root_perms          = true,
  Boolean                 $disable_rc_local           = true,
  Boolean                 $manage_root_user           = true,
  Boolean                 $manage_root_group          = true,
  Boolean                 $dns_autoconf               = true
) inherits ::simp::params {

  if empty($rsync_stunnel) and defined('$::servername') {
    $_rsync_stunnel = $::servername
  }
  else {
    $_rsync_stunnel = $rsync_stunnel
  }

  if !empty($_rsync_stunnel)    { validate_net_list($_rsync_stunnel) }

  if !$enable_filebucketing {
    File { backup => false }
  }
  else {
    File { backup => true }
  }

  if $filebucket_server {
    validate_net_list($filebucket_server)

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

  if $use_fips {
    include '::fips'
  }

  if $use_sudoers_aliases {
    include '::simp::sudoers'
  }

  if $version_info {
    include '::simp::version'
  }

  if $manage_root_metadata {
    include '::simp::root_user'
  }

  if $dns_autoconf {
    include '::simp::dns_autoconf'
  }

  if $puppet_server_ip and !empty($puppet_server){
    validate_net_list($puppet_server_ip)

    $l_pserver_alias = split($puppet_server,'.')

    host { $puppet_server:
      ensure       => 'present',
      host_aliases => $l_pserver_alias[0],
      ip           => $puppet_server_ip
    }
  }

  runlevel { $runlevel: }

  if $disable_rc_local {
    file { '/etc/rc.d/rc.local':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => "Managed by Puppet, manual changes will be erased\n"
    }
    file { '/etc/rc.local':
      ensure => 'symlink',
      target => '/etc/rc.d/rc.local'
    }
  }

  if $max_logins {
    pam::limits::add { 'max_logins':
      domain => '*',
      type   => 'hard',
      item   => 'maxlogins',
      value  => $max_logins,
      order  => '100'
    }
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

  file { "${facts['puppet_vardir']}/simp":
    ensure => 'directory',
    mode   => '0750',
    owner  => 'root',
    group  => 'root'
  }

}
