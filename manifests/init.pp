# This class provides the basis of what a native SIMP system should
# be. It is expected that users may deviate from this configuration
# over time, but this should be an effective starting place.
#
# @param is_mail_server
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
# @param sssd
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
# @param version_info
#   Drops SIMP and SIMP-version related information to the filesystem.
#
# @param manage_root_metadata
#   Include the simp::root_user class, which manages resources related to the root user.
#
# @param enable_filebucketing
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
# @params runlevel
#   Expects: 1-5, rescue, multi-user, or graphical
#   The default runlevel to which the system should be set.
#
# @params max_logins
#   The number of logins that an account may have on the system at a given time
#   as enforced by PAM. Set to undef to disable.
#
#   As set, meets CCE-27457-1
#
# @params manage_root_perms
#   Ensure that /root has restricted permissions and proper SELinux
#   contexts.
#
# @params disable_rc_local
#   If true, disable the use of the /etc/rc.local file.
#
# @params dns_autoconf
#   If true, autoconfigure named if the dns::servers include the host.
#
# == Hiera Variables
#
# These variables are not necessarily used directly by this class but
# are quite useful in getting your system functioning easily.
#
# @param sssd
#   See above
#
# @param simplib::timezone
# Default: GMT
#   Set your system timezone.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp (
  Boolean                    $is_mail_server             = true,
  String                     $rsync_stunnel              = hiera('rsync::stunnel',hiera('puppet::server',''),''),
  Boolean                    $fips                       = simplib::lookup('simp_options::fips', { 'default_value' => false }),
  Boolean                    $ldap                       = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean                    $sssd                       = simplib::lookup('simp_options::sssd', { 'default_value' => true }),
  Boolean                    $use_ssh_global_known_hosts = false,
  Boolean                    $use_stock_sssd             = true,
  Boolean                    $version_info               = true,
  Boolean                    $manage_root_metadata       = true,
  Boolean                    $enable_filebucketing       = true,
  Optional[Simplib::Netlist] $filebucket_server          = undef,
  Simplib::Host              $puppet_server              = defined('$::servername') ? { true => $::servername, default => hiera('puppet::server','') },
  Optional[Simplib::Host]    $puppet_server_ip           = undef,
  Boolean                    $use_sudoers_aliases        = true,
  String                     $runlevel                   = '3',
  Integer[0]                 $max_logins                 = 10,
  Boolean                    $manage_root_perms          = true,
  Boolean                    $disable_rc_local           = true,
  Boolean                    $manage_root_user           = true,
  Boolean                    $manage_root_group          = true,
) {

  if empty($rsync_stunnel) and defined('$::servername') {
    $_rsync_stunnel = $::servername
  }
  else {
    $_rsync_stunnel = $rsync_stunnel
  }

  if !empty($_rsync_stunnel) { validate_net_list($_rsync_stunnel) }

  if !$enable_filebucketing {
    File { backup => false }
  }
  else {
    File { backup => true }
  }

  if $filebucket_server {

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

  if $ldap {
    include '::openldap::pam'
    include '::openldap::client'
  }

  if $sssd {
    if $use_stock_sssd {
      include '::simp::sssd::client'
    }
  }

  if $fips {
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

  if $puppet_server_ip and !empty($puppet_server){
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
    pam::limits::rule { 'max_logins':
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
    stunnel::connection { 'rsync':
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
