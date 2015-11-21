# == Class: simp::yum
#
# This class sets up the /etc/yum directory, and ensures that
# yum-skip-broken is installed.
#
# == Parameters
#
# [*servers*]
# Type: Array of FQDN or IP address
#   The FQDN or IP of the yum server to which to connect for the default
#   repositories.
#
# [*enable_simp_repos*]
# Type: Boolean
# Default: true
#   If true, enable the default SIMP repositories. You should probably
#   leave this as is unless you really know what you are doing.
#
# [*enable_auto_updates*]
# Type: Boolean
# Default: true
#   If true, enable the automatic yum cron job. If false, remove it.
#
# [*os_update_url*]
# Type: String
# Default: "http://YUM_SERVER/yum/${::operatingsystem}/${::operatingsystemmajrelease}/${::hardwaremodel}/Updates"
#   This is a specially crafted string that handles the case where you
#   want to pass in multiple yum servers.
#
#   The string YUM_SERVER (all caps) will be replaced with the various
#   $servers entries appropriately.
#
#   This is not ideal but there is no way to know exactly how you wish
#   to structure your repositories if you deviate from the base.
#
# [*simp_update_url*]
# Type: String
# Default: "http://YUM_SERVER/yum/SIMP/${::hardwaremodel}"
#   This is a specially crafted string that handles the case where you
#   want to pass in multiple yum servers.
#
#   The string YUM_SERVER (all caps) will be replaced with the various
#   $servers entries appropriately.
#
#   This is not ideal but there is no way to know exactly how you wish
#   to structure your repositories if you deviate from the base.
#
# [*simp_gpg_url*]
# Type: String
# Default: "http://YUM_SERVER/yum/SIMP"
#   This is a specially crafted string that handles GPG url creation.
#
#   The string YUM_SERVER (all caps) will be replaced with the various
#   $servers entries appropriately.
#
class simp::yum (
  $servers,
  $enable_simp_repos = true,
  $enable_auto_updates = true,
  $os_update_url = "http://YUM_SERVER/yum/${::operatingsystem}/${::operatingsystemmajrelease}/${::hardwaremodel}/Updates",
  $simp_update_url = "http://YUM_SERVER/yum/SIMP/${::hardwaremodel}",
  $simp_gpg_url = 'http://YUM_SERVER/yum/SIMP'

){
  validate_array($servers)
  validate_net_list($servers)
  validate_bool($enable_simp_repos)
  validate_bool($enable_auto_updates)

  if $enable_auto_updates {
    include 'simplib::yum_schedule'
  }
  else {
    cron { 'yum_update': ensure => 'absent' }
  }

  file { [
    '/etc/yum',
    '/etc/yum.repos.d'
  ]:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      recurse => true
  }

  if $enable_simp_repos {
    $_simp_repo_enable = 1
  }
  else {
    $_simp_repo_enable = 0
  }

  yumrepo { 'os_updates':
    baseurl         => simp_yumrepo_mangle($os_update_url,$servers),
    descr           => "All ${::operatingsystem} ${::operatingsystemmajrelease} ${::hardwaremodel} base packages and updates",
    enabled         => $_simp_repo_enable,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => $::operatingsystem ? {
      'RedHat' => "http://${servers[0]}/yum/${::operatingsystem}/${::operatingsystemmajrelease}/${::hardwaremodel}/RPM-GPG-KEY-redhat-release",
      default  => "http://${servers[0]}/yum/${::operatingsystem}/${::operatingsystemmajrelease}/${::hardwaremodel}/RPM-GPG-KEY-${::operatingsystem}-${::operatingsystemmajrelease}",
    },
    keepalive       => 0,
    metadata_expire => '3600',
    tag             => 'firstrun'
  }

  yumrepo { 'simp':
    baseurl         => simp_yumrepo_mangle($simp_update_url,$servers),
    descr           => 'SIMP Packages',
    enabled         => $_simp_repo_enable,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => simp_yumrepo_gpgkeys($simp_gpg_url,$servers),
    keepalive       => 0,
    metadata_expire => '3600',
    tag             => 'firstrun'
  }
}