# @summary This is a set of applications that you will want on most systems
#
# Services this class manages:
#   * irqbalance (enabled by default by vendor)
#   * netlabel   (not installed by vendor)
#
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
#   DEPRECATED: This functionality is not required for normal operation of the
#   system and should be moved to external management.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::base_apps (
  Simp::PackageEnsure       $ensure               = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  Optional[Array[String,1]] $extra_apps           = undef,
  Optional[Boolean]         $manage_elinks_config = undef
) {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  $core_apps = [
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

  # Puppet cannot enable these services because there is no
  # init.d script or systemd script to do so.

  svckill::ignore { 'quotaon': }
  svckill::ignore { 'messagebus': }
}
