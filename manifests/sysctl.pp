# Sets sysctl settings that are useful from a general 'modern system'
# point of view.
#
# There are also items in this list that are particularly useful for
# general system security.
#
# See the kernel documentation for the functionality of each variable.
#
class simp::sysctl (
  # Performance Related Settings
  $net__netfilter__nf_conntrack_max      = '655360',
  $net__unix__max_dgram_qlen             = '50',
  $net__ipv4__neigh__default__gc_thresh3 = '2048',
  $net__ipv4__neigh__default__gc_thresh2 = '1024',
  $net__ipv4__neigh__default__gc_thresh1 = '32',
  $net__ipv4__neigh__default__proxy_qlen = '92',
  $net__ipv4__neigh__default__unres_qlen = '6',
  $net__ipv4__tcp_rmem                   = '4096 98304 16777216',
  $net__ipv4__tcp_wmem                   = '4096 65535 16777216',
  $net__ipv4__tcp_fin_timeout            = '30',
  $net__ipv4__tcp_rfc1337                = '1',
  $net__ipv4__tcp_keepalive_time         = '3600',
  $net__ipv4__tcp_mtu_probing            = '1',
  $net__ipv4__tcp_no_metrics_save        = '0',
  $net__core__rmem_max                   = '16777216',
  $net__core__wmem_max                   = '16777216',
  $net__core__optmem_max                 = '20480',
  $net__core__netdev_max_backlog         = '2048',
  $net__core__somaxconn                  = '2048',
  $net__ipv4__tcp_tw_reuse               = '1',
  # Security Related Settings
  $fs__suid_dumpable = '0',                                       # CCE-27044-7
  # If you change this, make sure you create the leading directories!
  $kernel__core_pattern    = '/var/core/%u_%g_%p_%t_%h_%e.core',
  $kernel__core_pipe_limit = '0',
  $kernel__core_uses_pid   = '1',
  $kernel__dmesg_restrict  = '1',                                 # CCE-27366-4
  # Does not apply to RHEL 7 systems
  $kernel__exec_shield                            = '1',          # CCE-27007-4
  $kernel__panic                                  = '10',
  $kernel__randomize_va_space                     = '2',          # CCE-26999-3
  $kernel__sysrq                                  = '0',
  $net__ipv4__conf__all__accept_redirects         = '0',          # CCE-27027-2
  $net__ipv4__conf__all__accept_source_route      = '0',          # CCE-27037-1
  $net__ipv4__conf__all__log_martians             = '1',          # CCE-27066-0
  $net__ipv4__conf__all__rp_filter                = '1',          # CCE-26979-5
  $net__ipv4__conf__all__secure_redirects         = '0',          # CCE-26854-0
  $net__ipv4__conf__all__send_redirects           = '0',          # CCE-27004-1
  $net__ipv4__conf__default__accept_redirects     = '0',          # CCE-27015-7
  $net__ipv4__conf__default__accept_source_route  = '0',          # CCE-26983-7
  $net__ipv4__conf__default__rp_filter            = '1',          # CCE-26915-9
  $net__ipv4__conf__default__secure_redirects     = '0',          # CCE-26831-8
  $net__ipv4__conf__default__send_redirects       = '0',          # CCE-27001-7
  $net__ipv4__icmp_echo_ignore_broadcasts         = '1',          # CCE-26883-9
  $net__ipv4__icmp_ignore_bogus_error_responses   = '1',          # CCE-26993-6
  $net__ipv4__tcp_challenge_ack_limit             = '2147483647', # CVE-2016-5696 mitigation
  $net__ipv4__tcp_max_syn_backlog                 = '4096',
  $net__ipv4__tcp_syncookies                      = '1',          # CCE-27053-8
  $net__ipv6__conf__all__accept_redirects         = '0',
  $net__ipv6__conf__all__autoconf                 = '0',
  $net__ipv6__conf__all__forwarding               = '0',
  $net__ipv6__conf__default__accept_ra            = '0',          # CCE-27164-3
  $net__ipv6__conf__default__accept_ra_defrtr     = '0',          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  $net__ipv6__conf__default__accept_ra_pinfo      = '0',          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  $net__ipv6__conf__default__accept_ra_rtr_pref   = '0',          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  $net__ipv6__conf__default__accept_redirects     = '0',          # CCE-27166-8
  $net__ipv6__conf__default__autoconf             = '0',          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  $net__ipv6__conf__default__dad_transmits        = '0',          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  $net__ipv6__conf__default__max_addresses        = '1',          # SSG network_ipv6_limit_requests (No CCEs available at this time)
  $net__ipv6__conf__default__router_solicitations = '0',          # SSG network_ipv6_limit_requests (No CCEs available at this time)

  $enable_ipv6 = defined('$::enable_ipv6') ? { true => $::enable_ipv6, default => hiera('enable_ipv6',true) }
) {

  validate_integer($net__netfilter__nf_conntrack_max)
  validate_integer($net__unix__max_dgram_qlen)
  validate_integer($net__ipv4__neigh__default__gc_thresh3)
  validate_integer($net__ipv4__neigh__default__gc_thresh2)
  validate_integer($net__ipv4__neigh__default__gc_thresh1)
  validate_integer($net__ipv4__neigh__default__proxy_qlen)
  validate_integer($net__ipv4__neigh__default__unres_qlen)
  validate_re($net__ipv4__tcp_rmem,'^\d+ \d+ \d+$')
  validate_re($net__ipv4__tcp_wmem,'^\d+ \d+ \d+$')
  validate_integer($net__ipv4__tcp_fin_timeout)
  validate_array_member($net__ipv4__tcp_rfc1337,['0','1'])
  validate_integer($net__ipv4__tcp_keepalive_time)
  validate_array_member($net__ipv4__tcp_mtu_probing,['0','1','2'])
  validate_array_member($net__ipv4__tcp_no_metrics_save,['0','1'])
  validate_integer($net__core__rmem_max)
  validate_integer($net__core__wmem_max)
  validate_integer($net__core__optmem_max)
  validate_integer($net__core__netdev_max_backlog)
  validate_integer($net__core__somaxconn)
  validate_array_member($fs__suid_dumpable,['0','1'])
  validate_sysctl_value('kernel.core_pattern',$kernel__core_pattern)
  validate_array_member($kernel__core_uses_pid,['0','1'])
  validate_array_member($kernel__dmesg_restrict,['0','1'])
  validate_array_member($kernel__exec_shield,['0','1'])
  validate_integer($kernel__panic)
  validate_array_member($kernel__randomize_va_space,['0','1','2'])
  validate_integer($kernel__sysrq)
  validate_array_member($net__ipv4__conf__all__accept_redirects,['0','1'])
  validate_array_member($net__ipv4__conf__all__accept_source_route,['0','1'])
  validate_array_member($net__ipv4__conf__all__log_martians,['0','1'])
  validate_array_member($net__ipv4__conf__all__rp_filter,['0','1','2'])
  validate_array_member($net__ipv4__conf__all__secure_redirects,['0','1'])
  validate_array_member($net__ipv4__conf__all__send_redirects,['0','1'])
  validate_array_member($net__ipv4__conf__default__accept_redirects,['0','1'])
  validate_array_member($net__ipv4__conf__default__accept_source_route,['0','1'])
  validate_array_member($net__ipv4__conf__default__rp_filter,['0','1','2'])
  validate_array_member($net__ipv4__conf__default__secure_redirects,['0','1'])
  validate_array_member($net__ipv4__conf__default__send_redirects,['0','1'])
  validate_array_member($net__ipv4__icmp_echo_ignore_broadcasts,['0','1'])
  validate_array_member($net__ipv4__icmp_ignore_bogus_error_responses,['0','1'])
  validate_integer($net__ipv4__tcp_challenge_ack_limit)
  validate_integer($net__ipv4__tcp_max_syn_backlog)
  validate_array_member($net__ipv4__tcp_syncookies,['0','1'])
  validate_bool($enable_ipv6)
  validate_array_member($net__ipv6__conf__all__accept_redirects,['0','1'])
  validate_array_member($net__ipv6__conf__all__autoconf,['0','1'])
  validate_array_member($net__ipv6__conf__all__forwarding,['0','1'])
  validate_array_member($net__ipv6__conf__default__accept_ra,['0','1'])
  validate_array_member($net__ipv6__conf__default__accept_ra_defrtr,['0','1'])
  validate_array_member($net__ipv6__conf__default__accept_ra_pinfo,['0','1'])
  validate_array_member($net__ipv6__conf__default__accept_ra_rtr_pref,['0','1'])
  validate_array_member($net__ipv6__conf__default__accept_redirects,['0','1'])
  validate_array_member($net__ipv6__conf__default__autoconf,['0','1'])
  validate_array_member($net__ipv6__conf__default__dad_transmits,['0','1'])
  validate_integer($net__ipv6__conf__default__max_addresses)
  validate_array_member($net__ipv6__conf__default__router_solicitations,['0','1'])


  case $::operatingsystem {
    'RedHat','CentOS': {
      # Performance Related Settings
      sysctl {
        'net.unix.max_dgram_qlen'           : value => $net__unix__max_dgram_qlen;
        'net.ipv4.neigh.default.gc_thresh3' : value => $net__ipv4__neigh__default__gc_thresh3;
        'net.ipv4.neigh.default.gc_thresh2' : value => $net__ipv4__neigh__default__gc_thresh2;
        'net.ipv4.neigh.default.gc_thresh1' : value => $net__ipv4__neigh__default__gc_thresh1;
        'net.ipv4.neigh.default.proxy_qlen' : value => $net__ipv4__neigh__default__proxy_qlen;
        'net.ipv4.neigh.default.unres_qlen' : value => $net__ipv4__neigh__default__unres_qlen;
        'net.ipv4.tcp_rmem'                 : value => $net__ipv4__tcp_rmem;
        'net.ipv4.tcp_wmem'                 : value => $net__ipv4__tcp_wmem;
        'net.ipv4.tcp_fin_timeout'          : value => $net__ipv4__tcp_fin_timeout;
        'net.ipv4.tcp_rfc1337'              : value => $net__ipv4__tcp_rfc1337;
        'net.ipv4.tcp_keepalive_time'       : value => $net__ipv4__tcp_keepalive_time;
        'net.ipv4.tcp_mtu_probing'          : value => $net__ipv4__tcp_mtu_probing;
        'net.ipv4.tcp_no_metrics_save'      : value => $net__ipv4__tcp_no_metrics_save;
        'net.core.rmem_max'                 : value => $net__core__rmem_max;
        'net.core.wmem_max'                 : value => $net__core__wmem_max;
        'net.core.optmem_max'               : value => $net__core__optmem_max;
        'net.core.netdev_max_backlog'       : value => $net__core__netdev_max_backlog;
        'net.core.somaxconn'                : value => $net__core__somaxconn;
        'net.ipv4.tcp_tw_reuse'             : value => $net__ipv4__tcp_tw_reuse
      }

      # This may not exist until additional packages are present
      sysctl { 'net.netfilter.nf_conntrack_max':
        value  => $net__netfilter__nf_conntrack_max,
        silent => true
      }

      # Security Related Settings
      sysctl {
        'fs.suid_dumpable':                           value => $fs__suid_dumpable;
        'kernel.core_pattern':                        value => $kernel__core_pattern;
        'kernel.core_uses_pid':                       value => $kernel__core_uses_pid;
        'kernel.dmesg_restrict':                      value => $kernel__dmesg_restrict;
        'kernel.panic':                               value => $kernel__panic;
        'kernel.randomize_va_space':                  value => $kernel__randomize_va_space;
        'kernel.sysrq':                               value => $kernel__sysrq;
        'net.ipv4.conf.all.accept_redirects':         value => $net__ipv4__conf__all__accept_redirects;
        'net.ipv4.conf.all.accept_source_route':      value => $net__ipv4__conf__all__accept_source_route;
        'net.ipv4.conf.all.log_martians':             value => $net__ipv4__conf__all__log_martians;
        'net.ipv4.conf.all.rp_filter':                value => $net__ipv4__conf__all__rp_filter;
        'net.ipv4.conf.all.secure_redirects':         value => $net__ipv4__conf__all__secure_redirects;
        'net.ipv4.conf.all.send_redirects':           value => $net__ipv4__conf__all__send_redirects;
        'net.ipv4.conf.default.accept_redirects':     value => $net__ipv4__conf__default__accept_redirects;
        'net.ipv4.conf.default.accept_source_route':  value => $net__ipv4__conf__default__accept_source_route;
        # Done since we're applying heavy IPTables rules.;
        'net.ipv4.conf.default.rp_filter':            value => $net__ipv4__conf__default__rp_filter;
        'net.ipv4.conf.default.secure_redirects':     value => $net__ipv4__conf__default__secure_redirects;
        'net.ipv4.conf.default.send_redirects':       value => $net__ipv4__conf__default__send_redirects;
        'net.ipv4.icmp_echo_ignore_broadcasts':       value => $net__ipv4__icmp_echo_ignore_broadcasts;
        'net.ipv4.icmp_ignore_bogus_error_responses': value => $net__ipv4__icmp_ignore_bogus_error_responses;
        'net.ipv4.tcp_challenge_ack_limit':           value => $net__ipv4__tcp_challenge_ack_limit;
        'net.ipv4.tcp_max_syn_backlog':               value => $net__ipv4__tcp_max_syn_backlog;
        'net.ipv4.tcp_syncookies':                    value => $net__ipv4__tcp_syncookies;
      }

      file { '/var/core':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0640',
        before => [
          Sysctl['kernel.core_pattern'],
          Sysctl['kernel.core_uses_pid'],
        ]
      }

      if ( $::operatingsystem in ['RedHat','CentOS'] ) and ( $::operatingsystemmajrelease == '6' ) {
        sysctl { 'kernel.exec-shield': value => $kernel__exec_shield; }
      }

      if $enable_ipv6 {
        sysctl { 'net.ipv6.conf.all.disable_ipv6': value => '0'; }
          ->
        sysctl {
          'net.ipv6.conf.all.accept_redirects':         value => $net__ipv6__conf__all__accept_redirects;
          'net.ipv6.conf.all.autoconf':                 value => $net__ipv6__conf__all__autoconf;
          'net.ipv6.conf.all.forwarding':               value => $net__ipv6__conf__all__forwarding;
          'net.ipv6.conf.default.accept_ra':            value => $net__ipv6__conf__default__accept_ra;
          'net.ipv6.conf.default.accept_ra_defrtr':     value => $net__ipv6__conf__default__accept_ra_defrtr;
          'net.ipv6.conf.default.accept_ra_pinfo':      value => $net__ipv6__conf__default__accept_ra_pinfo;
          'net.ipv6.conf.default.accept_ra_rtr_pref':   value => $net__ipv6__conf__default__accept_ra_rtr_pref;
          'net.ipv6.conf.default.accept_redirects':     value => $net__ipv6__conf__default__accept_redirects;
          'net.ipv6.conf.default.autoconf':             value => $net__ipv6__conf__default__autoconf;
          'net.ipv6.conf.default.dad_transmits':        value => $net__ipv6__conf__default__dad_transmits;
          'net.ipv6.conf.default.max_addresses':        value => $net__ipv6__conf__default__max_addresses;
          'net.ipv6.conf.default.router_solicitations': value => $net__ipv6__conf__default__router_solicitations;
        }
      }
      else {
        if $facts['ipv6_enabled'] {
          sysctl { 'net.ipv6.conf.all.disable_ipv6': value => '1'; }
        }
      }
    }
    default : {
      warning('Only RedHat and CentOS are currently supported by "simp::sysctl"')
    }
  }
}
