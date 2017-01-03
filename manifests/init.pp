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
# @param version_info
#   Add SIMP version information onto the client in ``/etc/simp``
#
# @param puppet_server_hosts_entry
#   Add a ``host`` entry for the Puppet server to the catalog
#
#   * This has no effect if the ``$server_facts`` Hash is not populated
#
# @param enable_filebucketing
#   If true, enable the server-side filebucket for all managed files on the
#   client system.
#
# @param filebucket_server
#   Sets up a remote filebucket target if set
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
# @param fips
#   Enable FIPS mode for this system
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
class simp (
  Variant[Boolean,Enum['remote']]                                $mail_server                = true,
  Optional[Variant[Boolean,Simplib::Host]]                       $rsync_stunnel              = undef,
  Boolean                                                        $use_ssh_global_known_hosts = false,
  Boolean                                                        $version_info               = true,
  Boolean                                                        $puppet_server_hosts_entry  = true,
  Boolean                                                        $enable_filebucketing       = true,
  Optional[Simplib::Netlist]                                     $filebucket_server          = undef,
  Boolean                                                        $use_sudoers_aliases        = true,
  Variant[Enum['rescue','multi-user','graphical'], Integer[1,5]] $runlevel                   = 3,
  Boolean                                                        $restrict_max_logins        = true,
  Boolean                                                        $manage_root_metadata       = true,
  Boolean                                                        $manage_root_perms          = true,
  Boolean                                                        $manage_rc_local            = true,
  Boolean                                                        $pam                        = simplib::lookup('simp_options::pam', { 'default_value' => false }),
  Boolean                                                        $fips                       = simplib::lookup('simp_options::fips', { 'default_value' => false }),
  Boolean                                                        $ldap                       = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean                                                        $sssd                       = simplib::lookup('simp_options::sssd', { 'default_value' => true }),
  Boolean                                                        $stock_sssd                 = true
) {

  File { backup => $enable_filebucketing }

  if $filebucket_server { filebucket { 'main': server => $filebucket_server } }

  file { "${facts['puppet_vardir']}/simp":
    ensure => 'directory',
    mode   => '0750',
    owner  => 'root',
    group  => 'root'
  }

  runlevel { to_string($runlevel): }

  if ($sssd and $stock_sssd) { include '::simp::sssd::client' }

  if $fips { include '::fips' }

  if $use_sudoers_aliases { include '::simp::sudoers' }

  if $version_info { include '::simp::version' }

  if $manage_root_metadata { include '::simp::root_user' }

  if ($restrict_max_logins and $pam) { include '::simp::pam_rule::max_logins' }

  if $mail_server == 'remote' {
    include '::postfix::server'
  }
  elsif $mail_server {
    include '::postfix'
  }

  if $ldap {
    include '::openldap::client'

    if $pam { include '::openldap::pam' }
  }

  if $manage_rc_local { include '::simp::rc_local' }

  if $puppet_server_hosts_entry {
    if $server_facts and $server_facts['servername'] and $server_facts['serverip'] {
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
    if $rsync_stunnel == true {
      $_rsync_stunnel_svr = $server_facts['serverip']
    }
    else {
      $_rsync_stunnel_svr = $rsync_stunnel
    }

    stunnel::connection { 'rsync':
      connect => ["${_rsync_stunnel_svr}:8730"],
      accept  => '127.0.0.1:873'
    }
  }
}
