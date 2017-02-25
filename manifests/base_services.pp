# This class controls the state of various common system services that
# you will generally want running on your system.
#
# This class manages:
#   * irqbalance (enabled by default by vendor)
#   * netlabel   (not installed by vendor)
#
# On EL 7:
#   * mcstransd (disabled by default by vendor)
#
# On EL 6:
#   * haldaemon   (enabled by defauly by vendor)
#   * mcstrans    (not installed by vendor)
#   * portreserve (disabled by default by vendor)
#   * quota_nld   (stopped by deafult by vendor)
#   * restorecond (disabled by default by vendor)
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::base_services {

  package { 'irqbalance': ensure => 'latest' }
  service { 'irqbalance':
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    require    => Package['irqbalance']
  }

  package { 'netlabel_tools': ensure => 'latest' }
  service { 'netlabel':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['netlabel_tools']
  }

  package { 'mcstrans': ensure => 'latest' }

  case $facts['os']['name'] {
    'RedHat','CentOS': {
      if $facts['os']['release']['major'] > '6' {
        # For now, these will be commented out and ignored by svckill
        # Puppet cannot enable these services because there is no
        # init.d script or systemd script to do so.

        # service { 'quotaon': enable => true }
        # service { 'messagebus': enable  => true }
        svckill::ignore { 'quotaon': }
        svckill::ignore { 'messagebus': }

        service { 'mcstransd':
          enable     => true,
          hasrestart => true,
          hasstatus  => false,
          require    => Package['mcstrans']
        }
      }
      else {
        package { 'hal': ensure => 'latest' }
        service { 'haldaemon':
          ensure     => 'running',
          enable     => true,
          hasrestart => true,
          hasstatus  => true,
          require    => Package['hal']
        }

        service { 'mcstrans':
          enable     => true,
          hasrestart => true,
          hasstatus  => false,
          require    => Package['mcstrans']
        }

        # portreserve will only start if there is a file in the conf directory
        # such as: cups ipp dhcpd named slapd ldaps
        package { 'portreserve': ensure => 'latest' }
        service { 'portreserve':
          ensure     => 'running',
          enable     => true,
          hasrestart => true,
          hasstatus  => false
        }

        service { 'quota_nld':
          ensure     => 'running',
          enable     => true,
          hasrestart => true,
          hasstatus  => true
        }

        service { 'restorecond':
          enable     => true,
          hasrestart => true,
          hasstatus  => false
        }
      }
    }
    default: {
      fail("${facts['os']['name']} is not yet supported by ${module_name}")
    }
  }
}
