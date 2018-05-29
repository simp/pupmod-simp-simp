# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# This class provides the basis of what a native SIMP system should
# be. It is expected that users may deviate from this configuration
# over time, but this should be an effective starting place.
#
# @param mail_server
#   Install a local mail service on the system
#
#   * If ``true`` will install only a locally usable MTA
#   * If ``remote`` will install a full mail server capable of processing
#     remote connections
#       * If you use a remote server, you'll need to set the appropriate
#         parameters for the ``postfix`` class
#
# @param rsync_stunnel
#   The rsync server from which files should be retrieved
#
#   * May be set to ``false`` to disable the rsync stunnel connection
#   * If unset, will default to the Puppet server itself
#
# @param use_ssh_global_known_hosts Boolean
#   If true, use the ssh_global_known_hosts function to gather the various host
#   SSH public keys and populate the /etc/ssh/known_hosts file.
#
# @param puppet_server_hosts_entry
#   Add a ``host`` entry for the Puppet server to the catalog
#
#   * This has no effect if the ``$server_facts`` Hash is not populated
#
# @param use_sudoers_aliases
#   If true, enable simp site sudoers aliases
#
# @param runlevel
#   The default runlevel to which the system should be set
#
# @param restrict_max_logins
#   Enable restrictions of the number of simultaneous logins a user may have
#
#   * Has no effect if ``$pam`` is ``false``
#
# @param manage_ctrl_alt_del
#   Include the ``simp::ctrl_alt_del`` class, which, by default, disables the
#   use of ctrl_alt_del and logs all instances of the event.
#
# @param manage_root_metadata
#   Include the ``simp::root_user`` class, which manages resources related to
#   the ``root`` user
#
# @param manage_root_perms
#   Ensure that ``/root`` has restricted permissions and proper SELinux
#   contexts
#
# @param manage_rc_local
#   Include the ``simp::rc_local`` class
#
#   * This **disables** rc.local by default but you may also use it to set
#     custom content
#
# @param pam
#   Enable management of PAM resources via SIMP modules
#
# @param sssd
#   Enable management of SSSD resources via SIMP modules
#
# @param ldap
#   Enable management of LDAP resources via SIMP modules
#
# @param stock_sssd
#   Add a default setup that will successfully connect to the SIMP LDAP server,
#   if enabled, and will otherwise provide a functional SSSD stack for the
#   system
#
#   * Has no effect if ``$sssd`` is ``false``
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::scenario::base (
  Variant[Boolean,Enum['remote']] $mail_server                = $::simp::mail_server,
  Variant[Boolean,Simplib::Host]  $rsync_stunnel              = $::simp::rsync_stunnel,
  Boolean                         $use_ssh_global_known_hosts = $::simp::use_ssh_global_known_hosts,
  Boolean                         $puppet_server_hosts_entry  = $::simp::puppet_server_hosts_entry,
  Boolean                         $use_sudoers_aliases        = $::simp::use_sudoers_aliases,
  Simp::Runlevel                  $runlevel                   = $::simp::runlevel,
  Boolean                         $restrict_max_logins        = $::simp::restrict_max_logins,
  Boolean                         $manage_ctrl_alt_del        = $::simp::manage_ctrl_alt_del,
  Boolean                         $manage_root_metadata       = $::simp::manage_root_metadata,
  Boolean                         $manage_root_perms          = $::simp::manage_root_perms,
  Boolean                         $manage_rc_local            = $::simp::manage_rc_local,
  Boolean                         $pam                        = $::simp::pam,
  Boolean                         $ldap                       = $::simp::ldap,
  Boolean                         $sssd                       = $::simp::sssd,
  Boolean                         $stock_sssd                 = $::simp::stock_sssd
) inherits ::simp {

  assert_private()

  runlevel { to_string($runlevel): }

  if ($sssd and $stock_sssd) { include '::simp::sssd::client' }

  if $use_sudoers_aliases { include '::simp::sudoers' }

  if $manage_ctrl_alt_del { include '::simp::ctrl_alt_del' }

  if $manage_root_metadata { include '::simp::root_user' }

  if ($restrict_max_logins and $pam) { include '::simp::pam_limits::max_logins' }

  if $mail_server == 'remote' {
    include '::postfix::server'
  }
  elsif $mail_server {
    include '::postfix'
  }

  # Even if $ldap is true, if the host is on an IPA domain, do not include
  # simp_openldap::client
  # @see simp/simplib lib/facter/ipa.rb
  if $ldap and !$facts['ipa'] {
    include '::simp_openldap::client'
  }

  if $manage_rc_local { include '::simp::rc_local' }

  if $puppet_server_hosts_entry {
    if getvar('server_facts') and $server_facts['servername'] and $server_facts['serverip'] {
      $_pserver_alias = split($server_facts['servername'],'.')[0]

      host { $server_facts['servername']:
        ensure       => 'present',
        host_aliases => $_pserver_alias,
        ip           => $server_facts['serverip']
      }
    }
  }

  if $use_ssh_global_known_hosts {
    ssh_global_known_hosts()

    sshkey_prune { '/etc/ssh/ssh_known_hosts': }
  }

  if $rsync_stunnel {
    if $rsync_stunnel == true  {
      $_rsync_stunnel_svr = (($server_facts =~ Hash) and $server_facts['serverip']) ? {
        true    => $server_facts['serverip'],
        default => $facts['puppet_settings']['agent']['server']
      }
    }
    else {
      $_rsync_stunnel_svr = $rsync_stunnel
    }

    unless host_is_me($_rsync_stunnel_svr) {
      stunnel::connection { 'rsync':
        connect => ["${_rsync_stunnel_svr}:8730"],
        accept  => '127.0.0.1:873'
      }
    }
  }
}
