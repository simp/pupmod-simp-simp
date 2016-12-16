# This class sets up a host of common administrative functions including
# administrator group system access, auditor access, and default sudo rules.
#
# @params admin_group String
#   The group name of the administrators of the system.
#   This group will be provided with the ability to sudo to root on the system.
#
# @params passwordless_admin_sudo Boolean
#   If true, allow administrators to use sudo without a password. This is on by
#   default due to the expected use of SSH keys and lack of local passwords.
#
# @params auditor_group String
#   The group name of the system auditors group.
#   This group will be provided with the ability to perform selected safe
#   commands as root on the system for auditing purposes.
#
# @params passwordless_auditor_sudo Boolean
#   If true, allow auditors to use sudo without a password. This is on by
#   default due to the expected use of SSH keys and lack of local passwords.
#
# @params admin_allowed_from Array
#   The locations from which administrators are allowed to access the system.
#   Set to all locations by default.
#
# @params auditors_allowed_from Array
#   The locations from which auditors are allowed to access the system.
#   Set to client_nets by default with a fallback of ALL locations.
#
# @authors Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::admin (
  String        $admin_group               = 'administrators',
  Boolean       $passwordless_admin_sudo   = true,
  String        $auditor_group             = 'security',
  Boolean       $passwordless_auditor_sudo = true,
  Array[String] $admins_allowed_from       = ['ALL'],
  Array[String] $auditors_allowed_from     = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['ALL'] }),
  Boolean       $force_sudosh              = true
){
  include '::simp::sudoers'

  # Make sure that the administrators group can access your system remotely.
  # Without some entry like this, you will not be able to access the system
  # remotely at all and will only be able to access the local system as root.
  pam::access::manage { "Allow ${admin_group}":
    comment => "Allow the ${admin_group} to access the system from anywhere",
    users   => "(${admin_group})",
    origins => $admins_allowed_from
  }

  # Allow the auditors to access the system.
  pam::access::manage { "Allow ${auditor_group}":
    comment => "Allow the ${auditor_group} to access the system from anywhere",
    users   => "(${auditor_group})",
    origins => $auditors_allowed_from
  }

  # Set up some default sudoers entries

  sudo::alias::user { 'admins':
    content => [ $admin_group, 'wheel' ]
  }

  sudo::alias::user { 'auditors':
    content => [ $auditor_group ]
  }

  $_force_sudosh = $force_sudosh ? {
    true    => '/usr/bin/sudosh',
    default => 'ALL'
  }

  sudo::user_specification { 'admin_global':
    user_list => "%${admin_group}",
    host_list => 'ALL',
    runas     => 'ALL',
    cmnd      => $_force_sudosh,
    passwd    => !$passwordless_admin_sudo
  }

  # The following two are especially important if you're using sudosh.
  # They allow you to recover from destroying the certs in your environment.
  sudo::user_specification { 'admin_run_puppetd':
    user_list => "%${admin_group}",
    host_list => 'ALL',
    runas     => 'root',
    cmnd      => '/usr/sbin/puppetd',
    passwd    => false
  }

  sudo::user_specification { 'admin_run_puppetca':
    user_list => "%${admin_group}",
    host_list => 'ALL',
    runas     => 'root',
    cmnd      => '/usr/sbin/puppetca',
    passwd    => false
  }

  sudo::user_specification { 'admin_clean_puppet_certs':
    user_list => "%${admin_group}",
    host_list => 'ALL',
    runas     => 'root',
    # This really should be the ssldir from the client, but we need a
    # client_settings fact for that.
    cmnd      => "/bin/rm -rf ${settings::ssldir}",
    passwd    => false
  }

  sudo::user_specification { 'auditors':
    user_list => "%${auditor_group}",
    host_list => 'ALL',
    runas     => 'root',
    cmnd      => 'AUDIT',
    passwd    => !$passwordless_auditor_sudo
  }
}
