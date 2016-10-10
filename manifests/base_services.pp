# == Class: simp::base_services
#
# This class controls the state of various common system services that
# you will generally want running on your system.
#
# == Authors
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::base_services {

  package { 'mcstrans': ensure => 'latest' }

  # These services should be enabled, but not started if they can't be
  # found.
  service { 'irqbalance':
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
  }

  # These services need to be enabled and made sure to be running.
  package { 'netlabel_tools':
    ensure => 'latest'
  }
  
  service { 'netlabel':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['netlabel_tools']
  }

  case $::operatingsystem {
    'RedHat','CentOS': {
      if $::operatingsystemmajrelease > '6' {
        # For now, these will be commentd out and ignored by svckill
        # Puppet cannot enable these services because there is no
        # init.d script or systemd script to do so.

        #        service { 'quotaon': enable => true }
        #        service { 'messagebus': enable  => true }
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
        package { 'hal':      ensure => 'latest' }

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
      fail("${::operatingsystem} is not yet supported by ${module_name}")
    }
  }
}
