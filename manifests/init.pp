# This class provides an entry point to configuring your systems to take full
# advantage of SIMP capabilities.
#
# This is primarily done through the ``simp::scenario`` classes that provide
# specifically supported configurations of core SIMP systems and clients.
#
# If you're planning to use SIMP capabilities, you should always include this
# class.
#
# @param scenario
#   The SIMP 'scenario' that you wish to apply to your system
#
#   * See the classes under ``simp::scenario`` for details of each supported
#     option
#
# @param classes
#   A list of classes that you wish to include in your SIMP stack
#
#   * This Array has been enabled with the ``knockout_prefix`` of ``--``
#   * Any Array item in the lookup hierarchy that you prefix with ``--`` will
#     be **removed** from the Array
#
#   @example The following list would include the `apache` class and exclude
#     the `ntpd` class.
#     ```
#     ---
#     simp::classes:
#         - 'apache'
#         - '--ntpd'
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
#   Enable the filebucket for all managed files
#
# @param filebucket_name
#   The name of the filebucket that should be used
#
# @param filebucket_server
#   Sets up a remote filebucket target if set
#
# @param filebucket_path
#   The local system path to use as the filebucket
#
#   * Has no effect if ``$filebucket_server`` is set
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
  Hash                            $scenario_map,
  Enum['simp',
       'simp_lite',
       'poss',
       'none',
       'remote_access']           $scenario                   = 'simp',
  Boolean                         $enable_data_includes       = true,
  Optional[Array]                 $classes                    = [],
  Variant[Boolean,Enum['remote']] $mail_server                = true,
  Variant[Boolean,Simplib::Host]  $rsync_stunnel              = simplib::lookup('simp_options::rsync', { 'default_value' => true }),
  Boolean                         $use_ssh_global_known_hosts = false,
  Boolean                         $version_info               = true,
  Boolean                         $puppet_server_hosts_entry  = true,
  Boolean                         $enable_filebucketing       = false,
  String                          $filebucket_name            = 'simp',
  Optional[Simplib::Host]         $filebucket_server          = undef,
  Stdlib::Absolutepath            $filebucket_path            = "${facts['puppet_vardir']}/simp/filebucket",
  Boolean                         $use_sudoers_aliases        = true,
  Simp::Runlevel                  $runlevel                   = 3,
  Boolean                         $restrict_max_logins        = true,
  Boolean                         $manage_ctrl_alt_del        = true,
  Boolean                         $manage_root_metadata       = true,
  Boolean                         $manage_root_perms          = true,
  Boolean                         $manage_rc_local            = true,
  Boolean                         $pam                        = simplib::lookup('simp_options::pam', { 'default_value' => false }),
  Boolean                         $fips                       = simplib::lookup('simp_options::fips', { 'default_value' => false }),
  Boolean                         $ldap                       = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean                         $sssd                       = simplib::lookup('simp_options::sssd', { 'default_value' => true }),
  Boolean                         $stock_sssd                 = true,
) {

  if $scenario_map.has_key($scenario) {
    include simp::knockout(union($scenario_map[$scenario], $classes))
  } else {
    fail("ERROR - Invalid scenario '${scenario}' for the given scenario map.")
  }

  file { "${facts['puppet_vardir']}/simp":
    ensure => 'directory',
    mode   => '0750',
    owner  => 'root',
    group  => 'root'
  }

  if $enable_filebucketing {
    File { backup => $filebucket_name }

    if $filebucket_server {
      filebucket { $filebucket_name: server => $filebucket_server }
    }
    else {
      filebucket { $filebucket_name: path => $filebucket_path }
    }
  }

  if $version_info { include '::simp::version' }

}
# vim: set expandtab ts=2 sw=2:
