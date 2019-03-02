# Manage the state of kdump
#
# This module enables/disables kdump in the kernel and
# installs/removes the kexec-tools package as needed,
#
# This module does not configure the kdump configuration files.
#
# If it is desired for simp to not manage the state of kdump
# use the knockout prefix to remove it from the class list.
#
# @param enabled
#   Allow ``ctrl-alt-del`` to restart the system
#
# @param  crashkernel
#   The value for the crashdump boot parameter.
#
# @param package_ensure
#   The ensure value for installed packages.
#
class simp::kdump (
  Boolean   $enabled        = false,
  String    $crashkernel    = auto,
  String    $package_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })
) {

  simplib::assert_metadata( $module_name )

  $_package_ensure = $enabled ? {
    true  => $package_ensure,
    false => 'absent'
  }

  package { 'kexec-tools':
    ensure => $_package_ensure
  }

  $_kernel_ensure = $enabled ? {
    true  => 'present',
    false => 'absent'
  }

  kernel_parameter { 'crashkernel':
    ensure => $_kernel_ensure,
    value  => $crashkernel,
    notify => Reboot_notify['kdump_reboot']
  }

  reboot_notify { 'kdump_reboot':
    reason => 'The status of the crashkernel kernel parameter (used for kdump) has changed.'
  }

}
