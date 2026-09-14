# @summary Blacklist and disable kernel modules
#
# A bare `include simp::kmod_blacklist` manages **nothing**: `blacklist` is
# empty by default, module locking is opt-in via `lock_modules`, and the class
# only touches `/etc/modprobe.d` once at least one module is listed in
# `blacklist`, `custom_blacklist`, or `purge_blacklist`.
#
# The pre-10.0.0 behavior (the SCAP Security Guide blacklist enforced, module
# locking managed) is restored by enforcing the `simp:defaults` compliance
# profile shipped in `SIMP/compliance_profiles/`, which carries the default
# module list.
#
# @param enable_defaults
#   **Deprecated** and no longer needed: `blacklist` is empty by default, so
#   its contents are the opt-in. Setting this parameter logs a deprecation
#   warning.
#
#   * `false` is still honored for backwards compatibility and ignores
#     `blacklist` (only `custom_blacklist` is used), as it did before 10.0.0
#   * `true` has no effect
#
# @param blacklist
#   List of kernel modules to be blacklisted
#
#   * Empty by default. The `simp:defaults` compliance profile sets this to the
#     SCAP Security Guide list that the class enforced before 10.0.0.
#
# @param custom_blacklist
#   Additional kernel modules to be blacklisted
#
#   * Kept separate from `blacklist` so that a site can add modules on top of a
#     `blacklist` supplied by a compliance profile without overriding it
#
# @param purge_blacklist
#   Kernel modules to remove from the kmod blacklist (`kmod::blacklist { ...:
#   ensure => 'absent' }`)
#
#   * Use this to clean up entries that a previous configuration of this class
#     added. Modules that are also present in the effective blacklist are
#     ignored.
#
# @param produce_error
#   If set to true, any disabled modules will point to '/bin/false', which will
#   produce an error when anyone attempts to load the module. Default is false,
#   which will point to '/bin/true', which will not produce any error.
#
# @param allow_overrides
#   Allow the addition of kernel module rules that come before the disabling of
#   the module blacklist and disabling so that optional override autoloading
#   can work properly
#
#   * If this is not set, you will be unable to optionally override the
#     disabling of the modules
#
# @param lock_modules
#   Manage the `kernel.modules_disabled` sysctl
#
#   * `true`: Disallow all further modification to modules without a reboot
#   * `false`: Ensure module loading is unlocked (a reboot is required to fully
#     unlock a locked system)
#   * `undef` (default): Do not manage module locking at all
#   * Requires that the ``kernel.modules_disabled`` sysctl option is available
#
# @param notify_if_reboot_required
#   Trigger a 'reboot_notify' resource that will warn at every puppet run that
#   a reboot is required if necessary.
#
#   * Only used when `lock_modules` is set
#
class simp::kmod_blacklist (
  Array[String[1]]  $blacklist                 = [],
  Optional[Boolean] $enable_defaults           = undef,
  Array[String[1]]  $custom_blacklist          = [],
  Array[String[1]]  $purge_blacklist           = [],
  Boolean           $produce_error             = false,
  Boolean           $allow_overrides           = true,
  Optional[Boolean] $lock_modules              = undef,
  Boolean           $notify_if_reboot_required = true
) {
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if $enable_defaults =~ NotUndef {
    deprecation(
      'simp::kmod_blacklist::enable_defaults',
      'simp::kmod_blacklist::enable_defaults is deprecated and no longer needed: `blacklist` is empty by default, so its contents are the opt-in. Remove this parameter.',
      false,
    )
  }

  $_blacklist = $enable_defaults ? {
    false   => unique($custom_blacklist),
    default => unique($custom_blacklist + $blacklist),
  }

  $_unblacklist = $purge_blacklist - $_blacklist

  # Only touch /etc/modprobe.d once the user has asked us to manage at least
  # one module. A bare include declares nothing.
  unless empty($_blacklist) and empty($_unblacklist) {
    # Overrides in modprobe are processed in shell glob alphabetical order
    if $allow_overrides {
      $_disable_file = '/etc/modprobe.d/zz_simp_disable.conf'
      $_obsolete_disable_file = '/etc/modprobe.d/00_simp_disable.conf'
    }
    else {
      $_disable_file = '/etc/modprobe.d/00_simp_disable.conf'
      $_obsolete_disable_file = '/etc/modprobe.d/zz_simp_disable.conf'
    }

    $_produce_error = $produce_error ? {
      true  => '/bin/false',
      false => '/bin/true',
    }

    $_disable_file_content = join($_blacklist.map |$mod| { "install ${mod} ${_produce_error}" }, "\n")

    file { $_disable_file:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      content => "${_disable_file_content}\n",
    }

    file { $_obsolete_disable_file: ensure => absent }

    $_blacklist.each |String $mod| {
      kmod::blacklist { $mod: }
    }

    $_unblacklist.each |String $mod| {
      kmod::blacklist { $mod: ensure => 'absent' }
    }
  }

  if $lock_modules =~ NotUndef {
    # None of this works if we don't actually have the kernel capability
    if $facts['simplib_sysctl'] and $facts['simplib_sysctl']['kernel.modules_disabled'] {
      if $lock_modules {
        include simplib::stages

        $_stage = 'simp_modprobe_lock'

        # Unfortunately, there is no way to make this *absolutely last*, so we just
        # have to do the best that we can.
        stage { $_stage: require => Stage['simp_finalize'] }
      }
      else {
        $_stage = 'main'
      }

      class { 'simp::kmod_blacklist::lock_modules':
        enable                    => $lock_modules,
        notify_if_reboot_required => $notify_if_reboot_required,
        stage                     => $_stage
      }
    }
    elsif $lock_modules {
      notify { 'simp::kmod_blacklist cannot lock modules':
        message => 'WARNING: Could not find `kernel.modules_disabled`, unable to lock kernel modules as requested by `simp::kmod_blacklist::lock_modules`'
      }
    }
  }
}
