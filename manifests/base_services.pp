# This class controls the state of various common system services that
# you will generally want running on your system.
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
        # For now, these will be commentd out and ignored by svckill
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
