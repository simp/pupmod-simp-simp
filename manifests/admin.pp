# Set up a host of common administrative functions including administrator
# group system access, auditor access, and default ``sudo`` rules
#
# @param admin_group
#   The group name of the Administrators for the system
#
#   * This group will be provided with the ability to ``sudo`` to ``root`` on
#     the system
#
# @param passwordless_admin_sudo
#   Allow administrators to use ``sudo`` without a password
#
#   * This is on by default due to the expected use of SSH keys without local
#     passwords
#
# @param auditor_group
#   The group name of the system auditors group
#
#   * This group is provided with the ability to perform selected safe commands
#     as ``root`` on the system for auditing purposes
#
# @param passwordless_auditor_sudo
#   Allow auditors to use ``sudo`` without a password
#
#   * This is on by default due to the expected use of SSH keys without local
#     passwords
#
# @param admins_allowed_from
#   The locations from which administrators are allowed to access the system
#
# @param auditors_allowed_from
#   The locations from which auditors are allowed to access the system
#
# @param force_logged_shell
#   Only allow ``sudo`` to a shell via a logging shell
#
# @param logged_shell
#   The name of the logged shell to use
#
# @param default_admin_sudo_cmnds
#   The set of commands that ``$admin_group`` should be able to run by default
#
# @param pam
#   Allow SIMP management of the PAM stack
#
#   * Without this, it is quite likely that your system is not going to respond
#     as expected with the rules in this class
#
# @param set_polkit_admin_group
#   If the system has PolicyKit support, will register ``$admin_group`` as a
#   valid administrative group on the system
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::admin (
  String                $admin_group               = 'administrators',
  Boolean               $passwordless_admin_sudo   = true,
  String                $auditor_group             = 'security',
  Boolean               $passwordless_auditor_sudo = true,
  Simplib::Netlist      $admins_allowed_from       = ['ALL'],
  Simplib::Netlist      $auditors_allowed_from     = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
  Boolean               $force_logged_shell        = true,
  Enum['sudosh','tlog'] $logged_shell              = 'tlog',
  Array[String[2]]      $default_admin_sudo_cmnds  = ['/bin/su - root'],
  Boolean               $pam                       = simplib::lookup('simp_options::pam', { 'default_value' => false }),
  Boolean               $set_polkit_admin_group    = true
){

  simplib::assert_metadata( $module_name )

  include 'simp::sudoers'

  if $pam {
    include '::pam'

    pam::access::rule { "Allow ${admin_group}":
      comment => "Allow the ${admin_group} to access the system from anywhere",
      users   => ["(${admin_group})"],
      origins => $admins_allowed_from
    }

    pam::access::rule { "Allow ${auditor_group}":
      comment => "Allow the ${auditor_group} to access the system from anywhere",
      users   => ["(${auditor_group})"],
      origins => $auditors_allowed_from
    }
  }

  # Set up some default sudoers entries

  sudo::alias::user { 'admins':
    content => [ $admin_group, 'wheel' ]
  }

  sudo::alias::user { 'auditors':
    content => [ $auditor_group ]
  }

  if $force_logged_shell {
    # We restrict this so we don't need a fallback
    if $logged_shell == 'sudosh' {
      include '::sudosh'

      $_shell_cmd = ['/usr/bin/sudosh']
    }
    else {
      # TODO: This should be removed when SIMP-5169 is resolved
      file { '/etc/profile.d/sudosh2.sh': ensure => 'absent' }
    }

    if $logged_shell == 'tlog' {
      include '::tlog::rec_session'

      $_shell_cmd = $default_admin_sudo_cmnds
    }
    else {
      # TODO: This should be removed when SIMP-5169 is resolved
      tidy { 'Tlog profile.d files':
        path    => '/etc/profile.d',
        matches => ['00-simp-tlog.*'],
        recurse => 1
      }
    }
  }
  else {
    $_shell_cmd = $default_admin_sudo_cmnds

    # TODO: These should be removed when SIMP-5169 is resolved
    tidy { 'Shell logging profile.d files':
      path    => '/etc/profile.d',
      matches => ['00-simp-tlog.*', 'sudosh2.*'],
      recurse => 1
    }
  }

  sudo::user_specification { 'admin global':
    user_list => ["%${admin_group}"],
    runas     => 'ALL',
    cmnd      => $_shell_cmd,
    passwd    => !$passwordless_admin_sudo
  }

  sudo::user_specification { 'auditors':
    user_list => ["%${auditor_group}"],
    runas     => 'root',
    cmnd      => ['AUDIT'],
    passwd    => !$passwordless_auditor_sudo
  }

  # The following two are especially important if you're using sudosh.
  # They allow you to recover from destroying the certs in your environment.
  sudo::user_specification { 'admin run puppet':
    user_list => ["%${admin_group}"],
    runas     => 'root',
    cmnd      => ['/usr/sbin/puppet', '/opt/puppetlabs/bin/puppet'],
    passwd    => !$passwordless_admin_sudo
  }

  # This logic is to avoid allowing admins to run `rm -rf` when the fact
  # doesn't exist
  case $facts['puppet_settings'] {
    Hash:    { $_ssldir = $facts['puppet_settings']['main']['ssldir'] }
    default: { $_ssldir = '/etc/puppetlabs/puppet/ssl' }
  }
  sudo::user_specification { 'admin clean puppet certs':
    user_list => ["%${admin_group}"],
    runas     => 'root',
    cmnd      => ["/bin/rm -rf ${$_ssldir}"],
    passwd    => !$passwordless_admin_sudo
  }

  $_polkit_ensure = ($set_polkit_admin_group and $facts['os']['release']['major'] >= '7') ? {
    true    => 'present',
    default => 'absent'
  }
  $_content = @("EOF")
    polkit.addAdminRule(function(action, subject) {
      return ["unix-group:${admin_group}"];
    });
    |EOF

  polkit::authorization::rule { "Set ${admin_group} group to a policykit administrator":
    ensure   => $_polkit_ensure,
    priority => 10,
    content  => $_content,
  }
}
