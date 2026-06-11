# @summary Sets sysctl settings that are useful from a general 'modern system'
# point of view.
#
# There are also items in this list that are particularly useful for
# general system security.
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
#   **DEPRECATED BY VENDOR WILL BE REMOVED IN NEXT RELEASE**
#
# @param kernel__panic
# @param kernel__randomize_va_space
# @param kernel__sysrq
# @param kernel__yama__ptrace_scope
#   Restricts the use of ``ptrace`` to processes with a defined relationship
#   (parent/child by default).  Set to ``1`` to satisfy STIG/SSG controls that
#   require ``kernel.yama.ptrace_scope`` >= 1 on EL 8/9 (e.g. RHEL-08-040282).
#   Valid kernel values are ``0``-``3``.
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
# @param core_dumps If true, enable core dumps on the system.
# @param core_dump_dir Directory to place core dumps
# @param pam SIMP catalyst for enabling PAM management
#   As set, meets CCE-27033-0
#
# @param ipv6
#   Set to ``false`` to disable IPv6 on your system via ``sysctl``
#
# @param unmanaged_sysctls
#   List of sysctl keys (e.g. ``net.core.somaxconn``) that this class should
#   leave alone. Use when another tool (``tuned``, ``NetworkManager``, a
#   container runtime, a vendor installer) already manages the value and SIMP
#   should not fight over it. Keys must match the actual sysctl name, not the
#   class parameter name.
#
# @author https://github.com/simp/pupmod-simp-simp/graphs/contributors
#
class simp::sysctl (
  Integer[0]           $net__netfilter__nf_conntrack_max               = 655360,
  Integer[0]           $net__unix__max_dgram_qlen                      = 50,
  Integer[0]           $net__ipv4__neigh__default__gc_thresh3          = 2048,
  Integer[0]           $net__ipv4__neigh__default__gc_thresh2          = 1024,
  Integer[0]           $net__ipv4__neigh__default__gc_thresh1          = 32,
  Integer[0]           $net__ipv4__neigh__default__proxy_qlen          = 92,
  Integer[0]           $net__ipv4__neigh__default__unres_qlen          = 6,
  Array[Integer,3,3]   $net__ipv4__tcp_rmem                            = [4096,98304,16777216],
  Array[Integer,3,3]   $net__ipv4__tcp_wmem                            = [4096,65535,16777216],
  Integer[0]           $net__ipv4__tcp_fin_timeout                     = 30,
  Integer[0,1]         $net__ipv4__tcp_rfc1337                         = 1,
  Integer[0]           $net__ipv4__tcp_keepalive_time                  = 3600,
  Integer[0,2]         $net__ipv4__tcp_mtu_probing                     = 1,
  Integer[0,1]         $net__ipv4__tcp_no_metrics_save                 = 0,
  Integer[0]           $net__core__rmem_max                            = 16777216,
  Integer[0]           $net__core__wmem_max                            = 16777216,
  Integer[0]           $net__core__optmem_max                          = 20480,
  Integer[0]           $net__core__netdev_max_backlog                  = 2048,
  Integer[0]           $net__core__somaxconn                           = 2048,
  Integer[0,1]         $net__ipv4__tcp_tw_reuse                        = 1,
  Integer[8912]        $fs__inotify__max_user_watches                  = 102400,
  Integer[0,1]         $fs__suid_dumpable                              = 0,          # CCE-27044-7
  String               $kernel__core_pattern                           = '/var/core/%u_%g_%p_%t_%h_%e.core',
  Integer[0]           $kernel__core_pipe_limit                        = 0,
  Integer[0,1]         $kernel__core_uses_pid                          = 1,
  Integer[0,1]         $kernel__dmesg_restrict                         = 1,          # CCE-27366-4
  Integer[0,1]         $kernel__exec_shield                            = 1,          # CCE-27007-4
  Integer[0]           $kernel__panic                                  = 10,
  Integer[0,2]         $kernel__randomize_va_space                     = 2,          # CCE-26999-3
  Integer[0]           $kernel__sysrq                                  = 0,
  Integer[0,3]         $kernel__yama__ptrace_scope                     = 1,          # STIG RHEL-08-040282 / CCE-80953-8
  Integer[0,1]         $net__ipv4__conf__all__accept_redirects         = 0,          # CCE-27027-2
  Integer[0,1]         $net__ipv4__conf__all__accept_source_route      = 0,          # CCE-27037-1
  Integer[0,1]         $net__ipv4__conf__all__log_martians             = 1,          # CCE-27066-0
  Integer[0,2]         $net__ipv4__conf__all__rp_filter                = 1,          # CCE-26979-5
  Integer[0,1]         $net__ipv4__conf__all__secure_redirects         = 0,          # CCE-26854-0
  Integer[0,1]         $net__ipv4__conf__all__send_redirects           = 0,          # CCE-27004-1
  Integer[0,1]         $net__ipv4__conf__default__accept_redirects     = 0,          # CCE-27015-7
  Integer[0,1]         $net__ipv4__conf__default__accept_source_route  = 0,          # CCE-26983-7
  Integer[0,1]         $net__ipv4__conf__default__log_martians         = 1,
  Integer[0,2]         $net__ipv4__conf__default__rp_filter            = 1,          # CCE-26915-9
  Integer[0,1]         $net__ipv4__conf__default__secure_redirects     = 0,          # CCE-26831-8
  Integer[0,1]         $net__ipv4__conf__default__send_redirects       = 0,          # CCE-27001-7
  Integer[0,1]         $net__ipv4__icmp_echo_ignore_broadcasts         = 1,          # CCE-26883-9
  Integer[0,1]         $net__ipv4__icmp_ignore_bogus_error_responses   = 1,          # CCE-26993-6
  Integer[0]           $net__ipv4__tcp_challenge_ack_limit             = 2147483647, # CVE-2016-5696 mitigation
  Integer[1]           $net__ipv4__tcp_max_syn_backlog                 = 4096,
  Integer[0,1]         $net__ipv4__tcp_syncookies                      = 1,          # CCE-27053-8
  Integer[0,1]         $net__ipv6__conf__all__accept_redirects         = 0,
  Integer[0,1]         $net__ipv6__conf__all__accept_source_route      = 0,          # CCI-000366 (STIG)
  Integer[0,1]         $net__ipv6__conf__all__autoconf                 = 0,
  Integer[0,1]         $net__ipv6__conf__all__forwarding               = 0,
  Integer[0,1]         $net__ipv6__conf__all__accept_ra                = 0,          # CCE-27164-3
  Integer[0,1]         $net__ipv6__conf__default__accept_ra            = 0,          # CCE-27164-3
  Integer[0,1]         $net__ipv6__conf__default__accept_ra_defrtr     = 0,          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Integer[0,1]         $net__ipv6__conf__default__accept_ra_pinfo      = 0,          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Integer[0,1]         $net__ipv6__conf__default__accept_ra_rtr_pref   = 0,          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Integer[0,1]         $net__ipv6__conf__default__accept_redirects     = 0,          # CCE-27166-8
  Integer[0,1]         $net__ipv6__conf__default__accept_source_route  = 0,
  Integer[0,1]         $net__ipv6__conf__default__autoconf             = 0,          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Integer[0,1]         $net__ipv6__conf__default__dad_transmits        = 0,          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Integer[0]           $net__ipv6__conf__default__max_addresses        = 1,          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  Integer[0,1]         $net__ipv6__conf__default__router_solicitations = 0,          # SSG network_ipv6_limit_requests (No CCEs available at this time)

  Boolean              $core_dumps                                     = false,
  Stdlib::AbsolutePath $core_dump_dir                                  = '/var/core',
  Boolean              $pam                                            = simplib::lookup('simp_options::pam', { 'default_value' => false }),
  Optional[Boolean]    $ipv6                                           = undef,
  Array[String]        $unmanaged_sysctls                              = []
) {
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  simplib::validate_sysctl_value('kernel.core_pattern',$kernel__core_pattern)
  simplib::validate_sysctl_value('fs.inotify.max_user_watches', $fs__inotify__max_user_watches)

  $_perf_settings = {
    'net.unix.max_dgram_qlen'           => $net__unix__max_dgram_qlen,
    'net.ipv4.neigh.default.gc_thresh3' => $net__ipv4__neigh__default__gc_thresh3,
    'net.ipv4.neigh.default.gc_thresh2' => $net__ipv4__neigh__default__gc_thresh2,
    'net.ipv4.neigh.default.gc_thresh1' => $net__ipv4__neigh__default__gc_thresh1,
    'net.ipv4.neigh.default.proxy_qlen' => $net__ipv4__neigh__default__proxy_qlen,
    'net.ipv4.neigh.default.unres_qlen' => $net__ipv4__neigh__default__unres_qlen,
    'net.ipv4.tcp_rmem'                 => join($net__ipv4__tcp_rmem, ' '),
    'net.ipv4.tcp_wmem'                 => join($net__ipv4__tcp_wmem, ' '),
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

  $_perf_settings.each |$_key, $_value| {
    unless $_key in $unmanaged_sysctls {
      sysctl { $_key: value => $_value }
    }
  }

  # This may not exist until additional packages are present
  unless 'net.netfilter.nf_conntrack_max' in $unmanaged_sysctls {
    sysctl { 'net.netfilter.nf_conntrack_max':
      value  => $net__netfilter__nf_conntrack_max,
      silent => true,
    }
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

  $_security_settings.each |$_key, $_value| {
    unless $_key in $unmanaged_sysctls {
      sysctl { $_key: value => $_value }
    }
  }

  if $core_dumps {
    $_core_before = ['kernel.core_pattern', 'kernel.core_uses_pid']
      .filter |$_k| { !($_k in $unmanaged_sysctls) }
      .map    |$_k| { Sysctl[$_k] }

    file { $core_dump_dir:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0640',
      before => $_core_before,
    }
  }
  if ($pam and !$core_dumps) {
    include 'pam'

    pam::limits::rule { 'prevent_core':
      domains => ['*'],
      type    => 'hard',
      item    => 'core',
      value   => 0,
      order   => 100,
    }
  }

  if $ipv6.is_a(Undef) {
    $_disable_ipv6 = 1
  }
  else {
    $_disable_ipv6 = $ipv6 ? { true => 0, false => 1 }
  }

  if $facts.dig('simplib_sysctl', 'net.ipv6.conf.all.disable_ipv6') {
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

    $_ipv6_settings.each |$_key, $_value| {
      unless $_key in $unmanaged_sysctls {
        sysctl { $_key: value => $_value }
      }
    }
  }
}
