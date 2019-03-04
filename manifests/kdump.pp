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
#  Enable kdump and install kexec-tools.
#
# @param  crashkernel
#   The value for the crashkernel boot parameter.
#   Note: if crashkernel is set to auto and < 1G of memry exists,
#   no memory will be allocated for kdump and the kernel will not start
#   kdump.  See the kdump documentation for more information.
#
# @param package_ensure
#   The ensure value for installed packages.
#
class simp::kdump (
  Boolean   $enabled        = false,
  String    $crashkernel    = 'auto',
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

  if $enabled {
    if $crashkernel == 'auto' and $facts['memorysize_mb'] < 1024 {
      notify { 'kdump_memory_warning' :
        message => 'kdump requires more then 1G of memory to make an automatic reservation.  Kdump may not be enabled.  See kdump documentation for more information'
      }
    }
    kernel_parameter { 'crashkernel':
      ensure => 'present',
      value  => $crashkernel,
      notify => Reboot_notify['kdump_reboot']
    }
  } else {
    kernel_parameter { 'crashkernel':
      ensure  => 'absent',
      notify => Reboot_notify['kdump_reboot']
    }
  }

  reboot_notify { 'kdump_reboot':
    reason => 'The status of the crashkernel kernel parameter (used for kdump) has changed.'
  }

}
