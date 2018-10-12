# Allows configuration for some kernel boot params for general security.
# This module is included by simp::sysctl, which also manages the
# run time kernel parameters.
#
# See the kernel documentation for the functionality of each variable.
#
# -------------------
# Spectre and Meltdown Kernel Paramaters
#
# @see https://access.redhat.com/articles/3311301
#
# @param  spectre_v2
#   If set, this will override the system default for spectre_v2 setting.
#
# @param pti
#   This setting overrides the page table isolation setting.
#   If true this adds the kpti boot param to ensure page table isolation
#   If false adds the nopti param to disable page table isolation
#---------------------
#
class simp::kernel_param (
  Optional[Boolean]                    $pti               = undef,
  Optional[Simp::SpectreV2]            $spectre_v2        = undef
) {

  if $facts['meltdown'] {
    case $pti {
      false : {
        $_ensure_nopti = 'present'
        $_ensure_kpti = 'absent' }
      true : {
        $_ensure_kpti = 'present'
        $_ensure_nopti = 'absent' }
      default : {
        $_ensure_kpti = 'absent'
        $_ensure_nopti = 'absent' }
    }

    kernel_parameter { 'nopti':
      ensure => $_ensure_nopti,
      notify => Reboot_notify['pti']
    }
    kernel_parameter { 'kpti':
      ensure => $_ensure_kpti,
      notify => Reboot_notify['pti']
    }

    reboot_notify { 'pti':
      reason => 'The status of the pti kernel parameter has changed'
    }
  }

  if $facts['spectre_v2'] {
    # The nospectre_v2 param is the same os spectre_v2=off and will
    # conflict with other settings so make sure it is
    # not there.
    kernel_parameter{ 'nospectre_v2':
      ensure => 'absent',
      notify => Reboot_notify['spectre_v2']
    }
    if $spectre_v2 {
      kernel_parameter { 'spectre_v2':
        value  => "${spectre_v2}",
        notify => Reboot_notify['spectre_v2']
        }
    } else {
      kernel_parameter{ 'spectre_v2':
        ensure => 'absent',
        notify => Reboot_notify['spectre_v2']
      }
    }

    reboot_notify { 'spectre_v2':
      reason => 'The status of the spectre_v2 kernel parameter has changed'
    }
  }
}
