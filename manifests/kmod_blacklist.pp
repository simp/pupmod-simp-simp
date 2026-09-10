# @summary Blacklist and disable kernel modules, optionally using the default
# set of entries from the SCAP Security Guide
#
# A bare `include simp::kmod_blacklist` manages **nothing**: the default
# blacklist is opt-in via `enable_defaults`, module locking is opt-in via
# `lock_modules`, and the module only touches `/etc/modprobe.d` once at least
# one module is listed in `blacklist` (with `enable_defaults => true`),
# `custom_blacklist`, or `purge_blacklist`.
#
# The pre-10.0.0 behavior (default blacklist enforced, module locking managed)
# is restored by enforcing the `simp:defaults` compliance profile shipped in
# `SIMP/compliance_profiles/`.
#
# @param enable_defaults
#   Enable to use the default `blacklist`, otherwise just the
#   `custom_blacklist` will be used
#
# @param blacklist
#   List of kernel modules to be blacklisted when `enable_defaults` is `true`
#
# @param produce_error
#   If set to true, any disabled modules will point to '/bin/false', which will
#   produce an error when anyone attempts to load the module. Default is false,
#   which will point to '/bin/true', which will not produce any error.
#
# @param custom_blacklist
#   Additional kernel modules to be blacklisted
#
# @param purge_blacklist
#   Kernel modules to remove from the kmod blacklist (`kmod::blacklist { ...:
#   ensure => 'absent' }`)
#
#   * Use this to clean up entries that a previous configuration of this class
#     added (for example, the default `blacklist` after switching
#     `enable_defaults` off). Modules that are also present in the effective
#     blacklist are ignored.
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
  Boolean            $enable_defaults           = false,
  Array[String[1],1] $blacklist                 = [
    'bluetooth',
    'cramfs',
    'dccp',
    'dccp_ipv4',
    'dccp_ipv6',
    'freevxfs',
    'hfs',
    'hfsplus',
    'ieee1394',
    'jffs2',
    'net-pf-31',
    'rds',
    'sctp',
    'squashfs',
    'tipc',
    'udf',
    'usb-storage',
  ],
  Array[String[1]]   $custom_blacklist          = [],
  Array[String[1]]   $purge_blacklist           = [],
  Boolean            $produce_error             = false,
  Boolean            $allow_overrides           = true,
  Optional[Boolean]  $lock_modules              = undef,
  Boolean            $notify_if_reboot_required = true
) {
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  $_blacklist = $enable_defaults ? {
    true    => unique($custom_blacklist + $blacklist),
    default => unique($custom_blacklist),
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
