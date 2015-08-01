# == Class: simp::server::rsync_shares
#
# Here we're setting up various rsync services that are needed by the SIMP
# clients the system configuration.
#
# If you don't have these provided somewhere, many of the modules will not
# function properly.
#
# If you want additional BIND DNS spaces to be served out from rsync, you'll
# need to enable them separately.
#
# == Parameters
# [*rsync_base*]
#   Type: Absolute Path
#   Default: hiera('rsync::base', versioncmp(simp_version(),'5') ? { '-1' => "/srv/rsync", default => "/srv/rsync/${::operatingsystem}/${::lsbmajdistrelease}"})
#     The path to the beginning of the rsync space for this system.
#
# [*use_stunnel*]
# Type: Boolean
# Default: hiera('rsync::server::use_stunnel',true)
#   If true, set hosts_allow to '127.0.0.1' so that the stunnel'd rsync is
#   used.
#
# [*hosts_allow*]
# Type: Net List
# Default: hiera('client_nets','127.0.0.1')
#   The hosts from which to allow access to the rsync shares.
#   This option has no effect if $use_stunnel is true.
#
# == Authors
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::server::rsync_shares (
  $rsync_base  = hiera('rsync::base', versioncmp(simp_version(),'5') ? { '-1' => "/srv/rsync", default => "/srv/rsync/${::operatingsystem}/${::lsbmajdistrelease}"}),
  $use_stunnel = hiera('rsync::server::use_stunnel',true),
  $hosts_allow = hiera('client_nets','127.0.0.1')
){
  include 'rsync::server::global'

  if $use_stunnel {
    $l_hosts_allow = '127.0.0.1'
  }
  else {
    $l_hosts_allow = $hosts_allow
  }
  rsync::server::section { 'default':
    comment     => 'The default file path',
    path        => "${rsync_base}/default",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'openldap_server':
    auth_users  => ['openldap_rsync'],
    comment     => 'Configuration for OpenLDAP',
    path        => "${rsync_base}/openldap/server",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'bind_dns_default':
    auth_users  => ['bind_dns_default_rsync'],
    comment     => 'Default DNS configurations for named',
    path        => "${rsync_base}/bind_dns/default",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'apache':
    auth_users     => ['apache_rsync'],
    comment        => 'Apache configurations',
    path           => "${rsync_base}/apache",
    hosts_allow    => '127.0.0.1',
    outgoing_chmod => 'o-rwx'
  }
  rsync::server::section { 'tftpboot':
    auth_users  => ['tftpboot_rsync'],
    comment     => 'Tftpboot server configurations',
    path        => "${rsync_base}/tftpboot",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'mcafee':
    comment     => 'McAfee DAT files',
    path        => "${rsync_base}/mcafee",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'clamav':
    comment     => 'ClamAV Virus Database Updates',
    path        => "${rsync_base}/clamav",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'dhcpd':
    auth_users  => ['dhcpd_rsync'],
    comment     => 'DHCP Configurations',
    path        => "${rsync_base}/dhcpd",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'snmp':
    comment     => 'SNMP MIBs and Modules',
    path        => "${rsync_base}/snmp",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'freeradius':
    auth_users  => ['freeradius_systems'],
    comment     => 'Freeradius configuration files',
    path        => "${rsync_base}/freeradius",
    hosts_allow => $l_hosts_allow
  }
  rsync::server::section { 'jenkins_plugins':
    comment     => 'Jenkins Configuration',
    path        => "${rsync_base}/jenkins_plugins",
    hosts_allow => $l_hosts_allow,
  }

  validate_absolute_path($rsync_base)
  validate_bool($use_stunnel)
  validate_net_list($hosts_allow)
}
