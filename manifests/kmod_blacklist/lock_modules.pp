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
# @param persist
#   Lock all modules at boot time.
#
#  * WARNING: It is *highly* likely that you will prevent important modules
#    from loading (such as networking) if you enable this. Test thoroughly
#    before enabling.
#
class simp::kmod_blacklist::lock_modules (
  $enable                    = true,
  $notify_if_reboot_required = true,
  $persist                   = false
) {

  simplib::assert_metadata( $module_name )

  if $enable {
    sysctl { 'kernel.modules_disabled':
      apply   => true,
      value   => 1,
      persist => $persist
    }
  }
  else {
    if ($facts['simplib_sysctl'] and ($facts['simplib_sysctl']['kernel.modules_disabled'] != 0)) {
      sysctl { 'kernel.modules_disabled':
        apply   => true,
        value   => 0,
        persist => $persist
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
