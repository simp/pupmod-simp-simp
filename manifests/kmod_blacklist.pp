# @summary This class provides a default set of blacklist entries per the SCAP
# Security Guide
#
# @param enable_defaults
#   Enable to use the default blacklist, otherwise just the
#   ``$custom_blacklist`` will be used
#
# @param blacklist
#   List of kernel modules to be blacklisted by default
#
# @param produce_error
#   If set to true, any disabled modules will point to '/bin/false', which will
#   produce an error when anyone attempts to load the module. Default is false,
#   which will point to '/bin/true', which will not produce any error.
#
# @param custom_blacklist
#   Additional kernel modules to be blacklisted
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
#   Disallow all further modification to modules without a reboot
#
#   * Requires that the ``kernel.modules_disabled`` sysctl option is available
#
# @param notify_if_reboot_required
#   Trigger a 'reboot_notify' resource that will warn at every puppet run that
#   a reboot is required if necessary.
#
class simp::kmod_blacklist (
  Boolean         $enable_defaults           = true,
  Array[String,1] $blacklist                 = [
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
    'usb-storage'
  ],
  Array[String]   $custom_blacklist          = [],
  Boolean         $produce_error             = false,
  Boolean         $allow_overrides           = true,
  Boolean         $lock_modules              = false,
  Boolean         $notify_if_reboot_required = true
) {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if $enable_defaults {
    $_blacklist = $custom_blacklist + $blacklist
    $_unblacklist = []
  }
  else {
    # If we don't want to enable the defaults, we need to make sure they've been
    # properly purged from the management files. Otherwise, the system is not
    # resetting to the expected state.

    $_blacklist = $custom_blacklist
    $_unblacklist = $blacklist - $custom_blacklist
  }

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
    content => "${_disable_file_content}\n"
  }

  file { $_obsolete_disable_file: ensure => absent }

  $_blacklist.each |String $mod| {
    kmod::blacklist { $mod: }
  }

  $_unblacklist.each |String $mod| {
    kmod::blacklist { $mod: ensure => 'absent' }
  }

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
