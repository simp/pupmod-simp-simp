# @summary Manage kernel parameters (sysctl) that are useful from a general
# 'modern system' and system security point of view.
#
# A bare `include simp::sysctl` manages **nothing**. Each sysctl parameter
# below maps to one kernel key (`net__ipv4__tcp_syncookies` =>
# `net.ipv4.tcp_syncookies`) and has three states:
#
# * `undef` (default): the key is not managed; whatever is in
#   `/etc/sysctl.conf` and the running kernel stays as it is
# * a value: the key is written to `/etc/sysctl.conf` and applied to the
#   running kernel
# * `'absent'`: the key is removed from `/etc/sysctl.conf`. The running
#   kernel value is **not** reset; it reverts to the kernel default at the next
#   reboot (unless another `sysctl.d` file sets it)
#
# Settings are written to `/etc/sysctl.conf`. At boot, `systemd-sysctl` applies
# it as `/etc/sysctl.d/99-sysctl.conf` (a symlink shipped by systemd), after
# the files in `/usr/lib/sysctl.d/` and most drop-ins in `/etc/sysctl.d/`, so a
# value set here overrides package and admin drop-ins. A drop-in that sorts
# after `99-sysctl.conf` still wins. Leaving a parameter unset leaves any
# drop-in value in force.
#
# The pre-11.0.0 behavior (every key below set to a hard-coded value, IPv6
# disabled, and core dumps restricted) is restored by enforcing the
# `simp:defaults` compliance profile shipped in `SIMP/compliance_profiles/`.
#
# See the kernel documentation for the functionality of each variable.
#
# Performance Related Settings
# @param net__netfilter__nf_conntrack_max
# @param net__unix__max_dgram_qlen
# @param net__ipv4__neigh__default__gc_thresh3
# @param net__ipv4__neigh__default__gc_thresh2
# @param net__ipv4__neigh__default__gc_thresh1
# @param net__ipv4__neigh__default__proxy_qlen
# @param net__ipv4__neigh__default__unres_qlen
# @param net__ipv4__tcp_rmem
# @param net__ipv4__tcp_wmem
# @param net__ipv4__tcp_fin_timeout
# @param net__ipv4__tcp_rfc1337
# @param net__ipv4__tcp_keepalive_time
# @param net__ipv4__tcp_mtu_probing
# @param net__ipv4__tcp_no_metrics_save
# @param net__core__rmem_max
# @param net__core__wmem_max
# @param net__core__optmem_max
# @param net__core__netdev_max_backlog
# @param net__core__somaxconn
# @param net__ipv4__tcp_tw_reuse
# @param fs__inotify__max_user_watches
#     Increase the number of inotify watches allowed in order to prevent
#     systemctl error: "Not Enough Disk Space" caused when it reaches limit.
#
# Security Related Settings:
# @param fs__suid_dumpable
#
# @param kernel__core_pattern
#   If you change this, make sure you create the leading directories!
#
# @param kernel__core_pipe_limit
# @param kernel__core_uses_pid
# @param kernel__dmesg_restrict
#
# @param kernel__exec_shield
#   **Deprecated** and has no effect: `kernel.exec_shield` does not exist on
#   any supported kernel. Setting it logs a deprecation warning. It will be
#   removed in the next major release.
#
# @param kernel__panic
# @param kernel__randomize_va_space
# @param kernel__sysrq
# @param kernel__yama__ptrace_scope
#   Restricts the use of ``ptrace`` to processes with a defined relationship
#   (parent/child by default). Set to ``1`` to satisfy STIG/SSG controls that
#   require ``kernel.yama.ptrace_scope`` >= 1 on EL 8/9 (e.g. RHEL-08-040282 /
#   CCE-80953-8). Valid kernel values are ``0``-``3``. Not set by the
#   ``simp:defaults`` profile.
# @param net__ipv4__conf__all__accept_redirects
# @param net__ipv4__conf__all__accept_source_route
# @param net__ipv4__conf__all__log_martians
# @param net__ipv4__conf__all__rp_filter
# @param net__ipv4__conf__all__secure_redirects
# @param net__ipv4__conf__all__send_redirects
# @param net__ipv4__conf__default__accept_redirects
# @param net__ipv4__conf__default__accept_source_route
# @param net__ipv4__conf__default__log_martians
# @param net__ipv4__conf__default__rp_filter
# @param net__ipv4__conf__default__secure_redirects
# @param net__ipv4__conf__default__send_redirects
# @param net__ipv4__icmp_echo_ignore_broadcasts
# @param net__ipv4__icmp_ignore_bogus_error_responses
# @param net__ipv4__tcp_challenge_ack_limit
# @param net__ipv4__tcp_max_syn_backlog
# @param net__ipv4__tcp_syncookies
# @param net__ipv6__conf__all__accept_redirects
# @param net__ipv6__conf__all__accept_source_route
# @param net__ipv6__conf__all__autoconf
# @param net__ipv6__conf__all__forwarding
# @param net__ipv6__conf__all__accept_ra
# @param net__ipv6__conf__default__accept_ra
# @param net__ipv6__conf__default__accept_ra_defrtr
# @param net__ipv6__conf__default__accept_ra_pinfo
# @param net__ipv6__conf__default__accept_ra_rtr_pref
# @param net__ipv6__conf__default__accept_redirects
# @param net__ipv6__conf__default__accept_source_route
# @param net__ipv6__conf__default__autoconf
# @param net__ipv6__conf__default__dad_transmits
# @param net__ipv6__conf__default__max_addresses
# @param net__ipv6__conf__default__router_solicitations
#
# @param core_dumps
#   * `true`: manage `core_dump_dir` as a directory for core dumps
#   * `false`: when `pam` is also `true`, add a PAM limits rule that prevents
#     core dumps (meets CCE-27033-0)
#   * `undef` (default): manage neither. On nodes where `/etc/security/limits.conf`
#     is managed by `pam::limits` (e.g. the `simp`, `simp_lite` and `one_shot`
#     scenarios, through `simp::pam_limits::max_logins`), that file is built
#     from the rules in the catalog, so a `prevent_core` rule written by an
#     earlier run is **removed**. Set `false` (or enforce `simp:defaults`) to
#     keep it.
#
# @param core_dump_dir Directory to place core dumps
#
# @param pam
#   SIMP catalyst for enabling PAM management. Only used when `core_dumps` is
#   `false`.
#
# @param ipv6
#   Manage ``net.ipv6.conf.all.disable_ipv6``
#
#   * ``false``: disable IPv6 (``disable_ipv6 = 1``)
#   * ``true``: enable IPv6 (``disable_ipv6 = 0``)
#   * ``'absent'``: remove the key from ``/etc/sysctl.conf``
#   * ``undef`` (default): leave it alone
#
#   @note This only affects systems where the IPv6 stack is present. If the
#     ``ipv6`` kernel module is not loaded, or IPv6 was disabled on the kernel
#     command line, the ``net.ipv6.*`` keys do not exist and cannot be set by
#     ``sysctl``. Use a kernel command line argument (``ipv6.disable=1``) if you
#     need IPv6 disabled before the stack is initialized.
#
# @param unmanaged_sysctls
#   **Deprecated**: leave the corresponding parameter unset (``undef``)
#   instead; a site can do that over a compliance profile with a Hiera ``~``.
#   List of sysctl keys (e.g. ``net.core.somaxconn``) that this class should
#   leave alone even when the matching parameter is set. Keys must match the
#   actual sysctl name, not the class parameter name. Setting it logs a
#   deprecation warning. It will be removed in the next major release.
#
# @author https://github.com/simp/pupmod-simp-simp/graphs/contributors
#
class simp::sysctl (
  Optional[Variant[Integer[0], Enum['absent']]]         $net__netfilter__nf_conntrack_max               = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__unix__max_dgram_qlen                      = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv4__neigh__default__gc_thresh3          = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv4__neigh__default__gc_thresh2          = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv4__neigh__default__gc_thresh1          = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv4__neigh__default__proxy_qlen          = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv4__neigh__default__unres_qlen          = undef,
  Optional[Variant[Array[Integer,3,3], Enum['absent']]] $net__ipv4__tcp_rmem                            = undef,
  Optional[Variant[Array[Integer,3,3], Enum['absent']]] $net__ipv4__tcp_wmem                            = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv4__tcp_fin_timeout                     = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__tcp_rfc1337                         = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv4__tcp_keepalive_time                  = undef,
  Optional[Variant[Integer[0,2], Enum['absent']]]       $net__ipv4__tcp_mtu_probing                     = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__tcp_no_metrics_save                 = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__core__rmem_max                            = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__core__wmem_max                            = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__core__optmem_max                          = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__core__netdev_max_backlog                  = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $net__core__somaxconn                           = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__tcp_tw_reuse                        = undef,
  Optional[Variant[Integer[8912], Enum['absent']]]      $fs__inotify__max_user_watches                  = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $fs__suid_dumpable                              = undef, # CCE-27044-7
  Optional[Variant[String, Enum['absent']]]             $kernel__core_pattern                           = undef,
  Optional[Variant[Integer[0], Enum['absent']]]         $kernel__core_pipe_limit                        = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $kernel__core_uses_pid                          = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $kernel__dmesg_restrict                         = undef, # CCE-27366-4
  Optional[Integer[0,1]]                                $kernel__exec_shield                            = undef, # CCE-27007-4
  Optional[Variant[Integer[0], Enum['absent']]]         $kernel__panic                                  = undef,
  Optional[Variant[Integer[0,2], Enum['absent']]]       $kernel__randomize_va_space                     = undef, # CCE-26999-3
  Optional[Variant[Integer[0], Enum['absent']]]         $kernel__sysrq                                  = undef,
  Optional[Variant[Integer[0,3], Enum['absent']]]       $kernel__yama__ptrace_scope                     = undef, # Set to 1 for STIG RHEL-08-040282 / CCE-80953-8
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__all__accept_redirects         = undef, # CCE-27027-2
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__all__accept_source_route      = undef, # CCE-27037-1
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__all__log_martians             = undef, # CCE-27066-0
  Optional[Variant[Integer[0,2], Enum['absent']]]       $net__ipv4__conf__all__rp_filter                = undef, # CCE-26979-5
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__all__secure_redirects         = undef, # CCE-26854-0
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__all__send_redirects           = undef, # CCE-27004-1
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__default__accept_redirects     = undef, # CCE-27015-7
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__default__accept_source_route  = undef, # CCE-26983-7
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__default__log_martians         = undef,
  Optional[Variant[Integer[0,2], Enum['absent']]]       $net__ipv4__conf__default__rp_filter            = undef, # CCE-26915-9
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__default__secure_redirects     = undef, # CCE-26831-8
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__conf__default__send_redirects       = undef, # CCE-27001-7
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__icmp_echo_ignore_broadcasts         = undef, # CCE-26883-9
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__icmp_ignore_bogus_error_responses   = undef, # CCE-26993-6
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv4__tcp_challenge_ack_limit             = undef, # CVE-2016-5696 mitigation
  Optional[Variant[Integer[1], Enum['absent']]]         $net__ipv4__tcp_max_syn_backlog                 = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv4__tcp_syncookies                      = undef, # CCE-27053-8
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__all__accept_redirects         = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__all__accept_source_route      = undef, # CCI-000366 (STIG)
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__all__autoconf                 = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__all__forwarding               = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__all__accept_ra                = undef, # CCE-27164-3
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__accept_ra            = undef, # CCE-27164-3
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__accept_ra_defrtr     = undef, # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__accept_ra_pinfo      = undef, # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__accept_ra_rtr_pref   = undef, # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__accept_redirects     = undef, # CCE-27166-8
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__accept_source_route  = undef,
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__autoconf             = undef, # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__dad_transmits        = undef, # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Optional[Variant[Integer[0], Enum['absent']]]         $net__ipv6__conf__default__max_addresses        = undef, # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Optional[Variant[Integer[0,1], Enum['absent']]]       $net__ipv6__conf__default__router_solicitations = undef, # SSG network_ipv6_limit_requests (No CCEs available at this time)

  Optional[Boolean]                                     $core_dumps                                     = undef,
  Stdlib::AbsolutePath                                  $core_dump_dir                                  = '/var/core',
  Boolean                                               $pam                                            = simplib::lookup('simp_options::pam', { 'default_value' => false }),
  Optional[Variant[Boolean, Enum['absent']]]            $ipv6                                           = undef,
  Array[String]                                         $unmanaged_sysctls                              = []
) {
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if $kernel__exec_shield =~ NotUndef {
    deprecation(
      'simp::sysctl::kernel__exec_shield',
      'simp::sysctl::kernel__exec_shield is deprecated and has no effect. Remove this parameter.',
      false,
    )
  }

  unless empty($unmanaged_sysctls) {
    deprecation(
      'simp::sysctl::unmanaged_sysctls',
      'simp::sysctl::unmanaged_sysctls is deprecated. Leave the matching simp::sysctl parameters unset (undef) instead.',
      false,
    )
  }

  # Match `absent` by type: Puppet's `==` and selector String cases ignore case
  if $kernel__core_pattern =~ String and !($kernel__core_pattern =~ Enum['absent']) {
    simplib::validate_sysctl_value('kernel.core_pattern', $kernel__core_pattern)
  }
  if $fs__inotify__max_user_watches =~ Integer {
    simplib::validate_sysctl_value('fs.inotify.max_user_watches', $fs__inotify__max_user_watches)
  }

  # Multi-value keys are written as a single space-separated string
  $_tcp_rmem = $net__ipv4__tcp_rmem ? {
    Array   => join($net__ipv4__tcp_rmem, ' '),
    default => $net__ipv4__tcp_rmem,
  }
  $_tcp_wmem = $net__ipv4__tcp_wmem ? {
    Array   => join($net__ipv4__tcp_wmem, ' '),
    default => $net__ipv4__tcp_wmem,
  }

  # Performance Related Settings
  $_perf_settings = {
    'net.unix.max_dgram_qlen'           => $net__unix__max_dgram_qlen,
    'net.ipv4.neigh.default.gc_thresh3' => $net__ipv4__neigh__default__gc_thresh3,
    'net.ipv4.neigh.default.gc_thresh2' => $net__ipv4__neigh__default__gc_thresh2,
    'net.ipv4.neigh.default.gc_thresh1' => $net__ipv4__neigh__default__gc_thresh1,
    'net.ipv4.neigh.default.proxy_qlen' => $net__ipv4__neigh__default__proxy_qlen,
    'net.ipv4.neigh.default.unres_qlen' => $net__ipv4__neigh__default__unres_qlen,
    'net.ipv4.tcp_rmem'                 => $_tcp_rmem,
    'net.ipv4.tcp_wmem'                 => $_tcp_wmem,
    'net.ipv4.tcp_fin_timeout'          => $net__ipv4__tcp_fin_timeout,
    'net.ipv4.tcp_rfc1337'              => $net__ipv4__tcp_rfc1337,
    'net.ipv4.tcp_keepalive_time'       => $net__ipv4__tcp_keepalive_time,
    'net.ipv4.tcp_mtu_probing'          => $net__ipv4__tcp_mtu_probing,
    'net.ipv4.tcp_no_metrics_save'      => $net__ipv4__tcp_no_metrics_save,
    'net.core.rmem_max'                 => $net__core__rmem_max,
    'net.core.wmem_max'                 => $net__core__wmem_max,
    'net.core.optmem_max'               => $net__core__optmem_max,
    'net.core.netdev_max_backlog'       => $net__core__netdev_max_backlog,
    'net.core.somaxconn'                => $net__core__somaxconn,
    'net.ipv4.tcp_tw_reuse'             => $net__ipv4__tcp_tw_reuse,
    'fs.inotify.max_user_watches'       => $fs__inotify__max_user_watches,
  }

  # This may not exist until additional packages are present
  $_conntrack_settings = {
    'net.netfilter.nf_conntrack_max' => $net__netfilter__nf_conntrack_max,
  }

  # Security Related Settings
  $_security_settings = {
    'fs.suid_dumpable'                           => $fs__suid_dumpable,
    'kernel.core_pattern'                        => $kernel__core_pattern,
    'kernel.core_pipe_limit'                     => $kernel__core_pipe_limit,
    'kernel.core_uses_pid'                       => $kernel__core_uses_pid,
    'kernel.dmesg_restrict'                      => $kernel__dmesg_restrict,
    'kernel.panic'                               => $kernel__panic,
    'kernel.randomize_va_space'                  => $kernel__randomize_va_space,
    'kernel.sysrq'                               => $kernel__sysrq,
    'kernel.yama.ptrace_scope'                   => $kernel__yama__ptrace_scope,
    'net.ipv4.conf.all.accept_redirects'         => $net__ipv4__conf__all__accept_redirects,
    'net.ipv4.conf.all.accept_source_route'      => $net__ipv4__conf__all__accept_source_route,
    'net.ipv4.conf.all.log_martians'             => $net__ipv4__conf__all__log_martians,
    'net.ipv4.conf.all.rp_filter'                => $net__ipv4__conf__all__rp_filter,
    'net.ipv4.conf.all.secure_redirects'         => $net__ipv4__conf__all__secure_redirects,
    'net.ipv4.conf.all.send_redirects'           => $net__ipv4__conf__all__send_redirects,
    'net.ipv4.conf.default.accept_redirects'     => $net__ipv4__conf__default__accept_redirects,
    'net.ipv4.conf.default.accept_source_route'  => $net__ipv4__conf__default__accept_source_route,
    'net.ipv4.conf.default.log_martians'         => $net__ipv4__conf__default__log_martians,
    # Done since we're applying heavy IPTables rules.
    'net.ipv4.conf.default.rp_filter'            => $net__ipv4__conf__default__rp_filter,
    'net.ipv4.conf.default.secure_redirects'     => $net__ipv4__conf__default__secure_redirects,
    'net.ipv4.conf.default.send_redirects'       => $net__ipv4__conf__default__send_redirects,
    'net.ipv4.icmp_echo_ignore_broadcasts'       => $net__ipv4__icmp_echo_ignore_broadcasts,
    'net.ipv4.icmp_ignore_bogus_error_responses' => $net__ipv4__icmp_ignore_bogus_error_responses,
    'net.ipv4.tcp_challenge_ack_limit'           => $net__ipv4__tcp_challenge_ack_limit,
    'net.ipv4.tcp_max_syn_backlog'               => $net__ipv4__tcp_max_syn_backlog,
    'net.ipv4.tcp_syncookies'                    => $net__ipv4__tcp_syncookies,
  }

  $_disable_ipv6 = $ipv6 ? {
    true    => 0,
    false   => 1,
    default => $ipv6,
  }

  $_ipv6_settings = {
    'net.ipv6.conf.all.accept_redirects'         => $net__ipv6__conf__all__accept_redirects,
    'net.ipv6.conf.all.accept_source_route'      => $net__ipv6__conf__all__accept_source_route,
    'net.ipv6.conf.all.autoconf'                 => $net__ipv6__conf__all__autoconf,
    'net.ipv6.conf.all.disable_ipv6'             => $_disable_ipv6,
    'net.ipv6.conf.all.forwarding'               => $net__ipv6__conf__all__forwarding,
    'net.ipv6.conf.all.accept_ra'                => $net__ipv6__conf__all__accept_ra,
    'net.ipv6.conf.default.accept_ra'            => $net__ipv6__conf__default__accept_ra,
    'net.ipv6.conf.default.accept_ra_defrtr'     => $net__ipv6__conf__default__accept_ra_defrtr,
    'net.ipv6.conf.default.accept_ra_pinfo'      => $net__ipv6__conf__default__accept_ra_pinfo,
    'net.ipv6.conf.default.accept_ra_rtr_pref'   => $net__ipv6__conf__default__accept_ra_rtr_pref,
    'net.ipv6.conf.default.accept_redirects'     => $net__ipv6__conf__default__accept_redirects,
    'net.ipv6.conf.default.accept_source_route'  => $net__ipv6__conf__default__accept_source_route,
    'net.ipv6.conf.default.autoconf'             => $net__ipv6__conf__default__autoconf,
    'net.ipv6.conf.default.dad_transmits'        => $net__ipv6__conf__default__dad_transmits,
    'net.ipv6.conf.default.max_addresses'        => $net__ipv6__conf__default__max_addresses,
    'net.ipv6.conf.default.router_solicitations' => $net__ipv6__conf__default__router_solicitations,
  }

  # `silent` is only enabled when the fact tells us the IPv6 stack is absent, in
  # which case these keys do not exist and augeasproviders_sysctl would fail on
  # them. Everywhere else we keep `silent => false` so that drift in the *running*
  # kernel value is still detected and corrected -- in silent mode the provider
  # skips the live value check entirely, which would weaken enforcement of the
  # hardening settings above.
  $_ipv6_silent = $facts.dig('simplib_sysctl', 'net.ipv6.conf.all.disable_ipv6') ? {
    undef   => true,
    default => false,
  }

  # [settings, silent]
  $_setting_groups = [
    [$_perf_settings, false],
    [$_conntrack_settings, true],
    [$_security_settings, false],
    [$_ipv6_settings, $_ipv6_silent],
  ]

  # Only keys whose parameter is set are declared; undef leaves the key alone.
  $_managed = $_setting_groups.reduce({}) |$memo, $group| {
    $memo + $group[0].filter |$_key, $_value| {
      $_value =~ NotUndef and !($_key in $unmanaged_sysctls)
    }.map |$_key, $_value| { [$_key, [$_value, $group[1]]] }.convert_to(Hash)
  }

  $_managed.each |$_key, $_setting| {
    $_attrs = $_setting[0] ? {
      Enum['absent'] => { 'ensure' => 'absent' },
      default        => { 'value' => $_setting[0] },
    }

    sysctl { $_key:
      silent => $_setting[1],
      *      => $_attrs,
    }
  }

  if $core_dumps =~ NotUndef {
    if $core_dumps {
      $_core_before = ['kernel.core_pattern', 'kernel.core_uses_pid']
        .filter |$_k| { $_k in $_managed }
        .map    |$_k| { Sysctl[$_k] }

      file { $core_dump_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0640',
        before => $_core_before,
      }
    }
    elsif $pam {
      include 'pam'

      pam::limits::rule { 'prevent_core':
        domains => ['*'],
        type    => 'hard',
        item    => 'core',
        value   => 0,
        order   => 100,
      }
    }
  }
}
