# Set up the local SIMP repositiories for disconnected environments.
#
# Generally, this is used by the ISO installation.
#
# @param servers
#   The FQDN or IP of the yum server to which to connect
#
# @param enable_simp_repos
#   Set up the repository for the SIMP packages
#
# @param enable_os_repos
#   Set up the repository for the OS package updates
#
# @param os_update_url
#   A specially crafted string that handles the case where you want to pass in
#   multiple yum servers
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
#   * This is not ideal but there is no way to know exactly how you wish to
#     structure your repositories if you deviate from the base
#
# @param os_gpg_url
#   A specially crafted string that handles GPG url creation
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
# @param simp_update_url
#   A specially crafted string that handles the case where you want to pass in
#   multiple yum servers
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
# @param simp_gpg_url
#   A specially crafted string that handles GPG url creation
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
class simp::yum::repo::simp_local (
  Simplib::Netlist                                     $servers,
  Boolean                                              $enable_simp_repos   = true,
  Boolean                                              $enable_os_repos     = true,
  Boolean                                              $enable_auto_updates = true,
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $os_update_url       = "https://YUM_SERVER/yum/${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}/Updates",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $os_gpg_url          = '',
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $simp_update_url     = "https://YUM_SERVER/yum/SIMP/${facts['architecture']}",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $simp_gpg_url        = ''
){
  assert_private()

  $_simp_repo_enable = $enable_simp_repos ? { true => 1, default => 0 }
  $_os_repo_enable   = $enable_os_repos ?   { true => 1, default => 0 }

  if empty($os_gpg_url) {
    $_temp_os_gpg_url = $facts['os']['name'] ? {
      'RedHat' => "https://YUM_SERVER/yum/${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}/RPM-GPG-KEY-redhat-release",
      default  => "https://YUM_SERVER/yum/${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}/RPM-GPG-KEY-${facts['os']['name']}-${facts['os']['release']['major']}"
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
    descr           => "All ${facts['os']['name']} ${facts['os']['release']['major']} ${facts['architecture']} base packages and updates",
    enabled         => $_os_repo_enable,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => join(split($_os_gpg_url,"\n"),"\n   "),
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => 3600,
    tag             => 'firstrun'
  }

  yumrepo { 'simp':
    baseurl         => simp_yumrepo_mangle($simp_update_url, $servers),
    descr           => 'SIMP Packages',
    enabled         => $_simp_repo_enable,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => join(split($_simp_gpg_url,"\n"),"\n   "),
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => 3600,
    tag             => 'firstrun'
  }
}
