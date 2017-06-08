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
  String           $admin_group               = 'administrators',
  Boolean          $passwordless_admin_sudo   = true,
  String           $auditor_group             = 'security',
  Boolean          $passwordless_auditor_sudo = true,
  Simplib::Netlist $admins_allowed_from       = ['ALL'],
  Simplib::Netlist $auditors_allowed_from     = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
  Boolean          $force_logged_shell        = true,
  Enum['sudosh']   $logged_shell              = 'sudosh',
  Boolean          $pam                       = simplib::lookup('simp_options::pam', { 'default_value' => false }),
  Boolean          $set_polkit_admin_group    = true
){

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
  }
  else {
    $_shell_cmd = ['ALL']
  }

  sudo::user_specification { 'admin_global':
    user_list => ["%${admin_group}"],
    host_list => [$facts['fqdn']],
    runas     => 'ALL',
    cmnd      => $_shell_cmd,
    passwd    => !$passwordless_admin_sudo
  }

  sudo::user_specification { 'auditors':
    user_list => ["%${auditor_group}"],
    host_list => [$facts['fqdn']],
    runas     => 'root',
    cmnd      => ['AUDIT'],
    passwd    => !$passwordless_auditor_sudo
  }

  # The following two are especially important if you're using sudosh.
  # They allow you to recover from destroying the certs in your environment.
  sudo::user_specification { 'admin_run_puppet':
    user_list => ["%${admin_group}"],
    host_list => [$facts['fqdn']],
    runas     => 'root',
    cmnd      => ['/usr/sbin/puppet', '/opt/puppetlabs/bin/puppet'],
    passwd    => !$passwordless_admin_sudo
  }

  sudo::user_specification { 'admin_clean_puppet_certs':
    user_list => ["%${admin_group}"],
    host_list => [$facts['fqdn']],
    runas     => 'root',
    cmnd      => ["/bin/rm -rf ${facts['puppet_settings']['ssldir']}"],
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
