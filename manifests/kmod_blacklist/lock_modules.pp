# This class toggles the ability to load any further kernel modules into the
# system until the system has been rebooted.
#
# This will only take effect if the system has the ``kernel.modules_disabled``
# sysctl feature.
#
# @param enable
#   Lock all module loading abilities
#
# @param notify_if_reboot_required
#   If the change requires the system to be rebooted to take effect, a
#   notification will be printed during puppet runs until the system has been
#   rebooted.
#
class simp::kmod_blacklist::lock_modules (
  $enable                    = true,
  $notify_if_reboot_required = true
) {
  if $enable {
    sysctl { 'kernel.modules_disabled':
      apply => true,
      value => 1
    }
  }
  else {
    if ($facts['simplib_sysctl'] and ($facts['simplib_sysctl']['kernel.modules_disabled'] != 0)) {
      sysctl { 'kernel.modules_disabled':
        apply => true,
        value => 0
      }

      if $notify_if_reboot_required {
        reboot_notify { 'kernel.modules_disabled unlock':
          reason => 'Module loading cannot be fully unlocked until a reboot is performed'
        }
      }
      else {
        reboot_notify { 'kernel.modules_disabled unlock':
          ensure => 'absent'
        }
      }
    }
  }
}
