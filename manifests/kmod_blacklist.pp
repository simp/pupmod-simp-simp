# @summary Blacklist and disable kernel modules
#
# A bare `include simp::kmod_blacklist` manages **nothing**: `modules` is
# empty by default, module locking is opt-in via `lock_modules`, and the class
# only touches `/etc/modprobe.d` once at least one module is listed in
# `modules`.
#
# Each module in `modules` gets a `kmod::blacklist` entry (in
# `/etc/modprobe.d/blacklist.conf` by default) and a `kmod::install` entry
# pointing the module at `/bin/true` (or `/bin/false`, see `produce_error`) in
# a SIMP-owned drop-in file so that it cannot be auto-loaded.
#
# The pre-10.0.0 behavior (the SCAP Security Guide blacklist enforced, module
# locking managed) is restored by enforcing the `simp:defaults` compliance
# profile shipped in `SIMP/compliance_profiles/`, which carries the default
# module list.
#
# @param modules
#   Kernel modules to blacklist and disable, as a Hash of module name =>
#   `kmod::blacklist` parameters
#
#   * An empty Hash of parameters (`bluetooth: {}`) blacklists the module with
#     the `kmod::blacklist` defaults
#   * `ensure: absent` removes the module's blacklist and install entries; use
#     it to drop a module from a list supplied by a compliance profile
#   * Any other `kmod::blacklist` parameter (e.g. `file`) is passed through.
#     `file` may not point at one of the SIMP disable files
#     (`/etc/modprobe.d/zz_simp_disable.conf`,
#     `/etc/modprobe.d/00_simp_disable.conf`), which this class manages;
#     compilation fails if it does
#   * Deep-merged across the Hiera hierarchy (see `lookup_options` in
#     `data/common.yaml`), so a site can add to or override entries supplied
#     by a compliance profile without restating the whole list
#   * Empty by default. The `simp:defaults` compliance profile sets this to the
#     SCAP Security Guide list that the class enforced before 10.0.0.
#
# @param blacklist
#   **Deprecated**, use `modules` instead. List of kernel modules to be
#   blacklisted. Each entry is added to `modules` with default options; an
#   entry that is also present in `modules` takes its options from `modules`.
#
# @param custom_blacklist
#   **Deprecated**, use `modules` instead. Additional kernel modules to be
#   blacklisted. Handled like `blacklist`.
#
# @param enable_defaults
#   **Deprecated** and no longer needed: `modules` is empty by default, so
#   its contents are the opt-in.
#
#   * `false` is still honored for backwards compatibility and ignores the
#     deprecated `blacklist` (only `custom_blacklist` and `modules` are used),
#     as it did before 10.0.0
#   * `true` has no effect
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
  Hash[String[1], Hash[String[1], Any]] $modules                   = {},
  Optional[Array[String[1]]]            $blacklist                 = undef,
  Optional[Array[String[1]]]            $custom_blacklist          = undef,
  Optional[Boolean]                     $enable_defaults           = undef,
  Boolean                               $produce_error             = false,
  Boolean                               $allow_overrides           = true,
  Optional[Boolean]                     $lock_modules              = undef,
  Boolean                               $notify_if_reboot_required = true
) {
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if $blacklist =~ NotUndef {
    deprecation(
      'simp::kmod_blacklist::blacklist',
      'simp::kmod_blacklist::blacklist is deprecated. List the modules in simp::kmod_blacklist::modules instead.',
      false,
    )
  }

  if $custom_blacklist =~ NotUndef {
    deprecation(
      'simp::kmod_blacklist::custom_blacklist',
      'simp::kmod_blacklist::custom_blacklist is deprecated. List the modules in simp::kmod_blacklist::modules instead.',
      false,
    )
  }

  if $enable_defaults =~ NotUndef {
    deprecation(
      'simp::kmod_blacklist::enable_defaults',
      'simp::kmod_blacklist::enable_defaults is deprecated and no longer needed: `modules` is empty by default, so its contents are the opt-in. Remove this parameter.',
      false,
    )
  }

  # Fold the deprecated Array parameters into the `modules` Hash with default
  # options. Explicit `modules` entries win.
  $_legacy_blacklist = $enable_defaults ? {
    false   => $custom_blacklist.lest || { [] },
    default => ($custom_blacklist.lest || { [] }) + ($blacklist.lest || { [] }),
  }

  $_modules = Hash($_legacy_blacklist.unique.map |$mod| { [$mod, {}] }) + $modules

  # Only touch /etc/modprobe.d once the user has asked us to manage at least
  # one module. A bare include declares nothing.
  unless empty($_modules) {
    # Overrides in modprobe are processed in shell glob alphabetical order
    if $allow_overrides {
      $_disable_file = '/etc/modprobe.d/zz_simp_disable.conf'
      $_obsolete_disable_file = '/etc/modprobe.d/00_simp_disable.conf'
    }
    else {
      $_disable_file = '/etc/modprobe.d/00_simp_disable.conf'
      $_obsolete_disable_file = '/etc/modprobe.d/zz_simp_disable.conf'
    }

    $_command = $produce_error ? {
      true  => '/bin/false',
      false => '/bin/true',
    }

    # The SIMP disable files are managed by this class; a module's `file`
    # override may not point at either of them (the obsolete one is removed
    # below, the current one holds the `install` entries).
    $_reserved_files = [$_disable_file, $_obsolete_disable_file]
    $_modules.each |String $mod, Hash $options| {
      if $options['file'] in $_reserved_files {
        fail("simp::kmod_blacklist: modules['${mod}']['file'] may not be a SIMP disable file (${$_reserved_files.join(', ')}); these are managed by this class")
      }
    }

    file { $_obsolete_disable_file: ensure => absent }

    $_modules.each |String $mod, Hash $options| {
      kmod::blacklist { $mod: * => $options }

      kmod::install { $mod:
        ensure  => $options['ensure'].lest || { 'present' },
        command => $_command,
        file    => $_disable_file,
      }
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
