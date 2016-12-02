# This class sets up the /etc/yum directory, and ensures that
# yum-skip-broken is installed.
#
# @param servers
#   Type: Array of FQDN or IP address
#   The FQDN or IP of the yum server to which to connect for the default
#   repositories.
#
# @param enable_simp_repos
#   If true, enable the default SIMP repositories. You should probably
#   leave this as is unless you really know what you are doing.
#
# @param enable_auto_updates
#   If true, enable the automatic yum cron job. If false, remove it.
#
# @param os_update_url
#   This is a specially crafted string that handles the case where you want to
#   pass in multiple yum servers.
#
#   The string YUM_SERVER (all caps) will be replaced with the various $servers
#   entries appropriately.
#
#   This is not ideal but there is no way to know exactly how you wish to
#   structure your repositories if you deviate from the base.
#
# @param os_gpg_url
#   If set, this is a specially crafted string that handles GPG url creation.
#
#   The string YUM_SERVER (all caps) will be replaced with the various
#   $servers entries appropriately.
#
#
# @param simp_update_url
#   This is a specially crafted string that handles the case where you
#   want to pass in multiple yum servers.
#
#   The string YUM_SERVER (all caps) will be replaced with the various
#   $servers entries appropriately.
#
#   This is not ideal but there is no way to know exactly how you wish
#   to structure your repositories if you deviate from the base.
#
# @param simp_gpg_url
#   This is a specially crafted string that handles GPG url creation.
#
#   The string YUM_SERVER (all caps) will be replaced with the various
#   $servers entries appropriately.
#
class simp::yum (
  Array[String]                                        $servers,
  Boolean                                              $enable_simp_repos    = true,
  Boolean                                              $enable_os_repos      = true,
  Boolean                                              $enable_auto_updates  = true,
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $os_update_url        = "https://YUM_SERVER/yum/${::operatingsystem}/${::operatingsystemmajrelease}/${::hardwaremodel}/Updates",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $os_gpg_url           = '',
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $simp_update_url      = "https://YUM_SERVER/yum/SIMP/${::hardwaremodel}",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $simp_gpg_url         = ''
){
  validate_net_list($servers)

  if $enable_auto_updates {
    include 'simp::yum_schedule'
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

  $_simp_repo_enable = $enable_simp_repos ? { true => 1, default => 0 }
  $_os_repo_enable   = $enable_os_repos ?   { true => 1, default => 0 }

  if empty($os_gpg_url) {
    $_temp_os_gpg_url = $::operatingsystem ? {
      'RedHat' => "https://YUM_SERVER/yum/${::operatingsystem}/${::operatingsystemmajrelease}/${::hardwaremodel}/RPM-GPG-KEY-redhat-release",
      default  => "https://YUM_SERVER/yum/${::operatingsystem}/${::operatingsystemmajrelease}/${::hardwaremodel}/RPM-GPG-KEY-${::operatingsystem}-${::operatingsystemmajrelease}"
    }

    $_os_gpg_url = simp_yumrepo_mangle($_temp_os_gpg_url, $servers)
  }
  else {
    $_os_gpg_url = simp_yumrepo_mangle($os_gpg_url, $servers)
  }

  if empty($simp_gpg_url) {
    $_simp_gpg_url = simp_yumrepo_gpgkeys('https://YUM_SERVER/yum/SIMP', $servers)
  }
  else {
    $_simp_gpg_url = simp_yumrepo_mangle($simp_gpg_url, $servers)
  }

  yumrepo { 'os_updates':
    baseurl         => simp_yumrepo_mangle($os_update_url, $servers),
    descr           => "All ${::operatingsystem} ${::operatingsystemmajrelease} ${::hardwaremodel} base packages and updates",
    enabled         => $_os_repo_enable,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => $_os_gpg_url,
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => '3600',
    tag             => 'firstrun'
  }

  yumrepo { 'simp':
    baseurl         => simp_yumrepo_mangle($simp_update_url, $servers),
    descr           => 'SIMP Packages',
    enabled         => $_simp_repo_enable,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => $_simp_gpg_url,
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => '3600',
    tag             => 'firstrun'
  }
}
