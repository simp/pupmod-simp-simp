# This is a set of applications that you will want on most systems
#
# Services this class manages:
#   * irqbalance (enabled by default by vendor)
#   * netlabel   (not installed by vendor)
#
#   On EL 6:
#     * haldaemon   (enabled by defauly by vendor)
#     * portreserve (disabled by default by vendor)
#     * quota_nld   (stopped by deafult by vendor)

# @param ensure
#   The ``$ensure`` status of all of the included packages
#
#   * Version pinning is not supported
#   * If you need version pinning, do not include this class
#
# @param extra_apps
#   A list of other applications that you wish to install
#
# @param manage_elinks_config
#   Add some useful settings to the global elinks configuration
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::base_apps (
  Simp::PackageEnsure       $ensure               = simplib::lookup('simp_options::ensure', { 'default_value' => 'installed' }),
  Optional[Array[String,1]] $extra_apps           = undef,
  Boolean                   $manage_elinks_config = true
) {

  $core_apps = [
    'dos2unix',
    'elinks',
    'hunspell',
    'lsof',
    'man',
    'man-pages',
    'mlocate',
    'pax',
    'pinfo',
    'sos',
    'star',
    'symlinks',
    'vim-enhanced',
    'words',
    'x86info',
    'irqbalance',
    'netlabel_tools',
    'bind-utils'
  ]
  $apps = $extra_apps ? {
    Array   => $core_apps + $extra_apps,
    default => $core_apps
  }
  package { $apps: ensure => $ensure }

  service { 'irqbalance':
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    require    => Package['irqbalance']
  }
  service { 'netlabel':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['netlabel_tools']
  }

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
      }
      else {
        package { ['hal','portreserve','quota']: ensure => $ensure }
        service { 'haldaemon':
          ensure     => 'running',
          enable     => true,
          hasrestart => true,
          hasstatus  => true,
          require    => Package['hal']
        }

        # portreserve will only start if there is a file in the conf directory
        # such as: cups ipp dhcpd named slapd ldaps
        service { 'portreserve':
          ensure     => 'running',
          enable     => true,
          hasrestart => true,
          hasstatus  => false,
          require    => Package['portreserve']
        }

        service { 'quota_nld':
          ensure     => 'running',
          enable     => true,
          hasrestart => true,
          hasstatus  => true,
          require    => Package['quota']
        }
      }
    }
    default: {
      fail("${facts['os']['name']} is not yet supported by ${module_name}")
    }
  }

  if $manage_elinks_config {
    file { '/etc/elinks.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package['elinks']
    }

    file_line { 'elinks_ui_lang':
      path    => '/etc/elinks.conf',
      line    => 'set ui.language = "System"',
      require => File['/etc/elinks.conf']
    }

    file_line { 'elinks_css_disable':
      path    => '/etc/elinks.conf',
      line    => 'set document.css.enable = 0',
      require => File['/etc/elinks.conf']
    }
  }
}
