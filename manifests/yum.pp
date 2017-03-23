# Set up the ``/etc/yum`` directory, and ensures that ``yum-skip-broken`` is
# installed.
#
# @param enable_auto_updates
#   Enable the automatic yum cron job
#
# @param enable_simp_local_repos
#   Point your system to the ``servers`` systems for obtaining package updates
#
#  * This will probably not apply if you are using r10k or Code Manager
#
# @param enable_simp_internet_repos
#   Point your system at all public repositories that are required for a SIMP
#   installation
#
#   * Requires Internet connectivity and a willingness to pull packages from
#     these public repositories
#
# @param simp_version
#   The version of SIMP that should be used if pointing to Internet
#   repositories
#
#   * Defaults to the version of SIMP that the **puppet server** is running
#
# @param enable_simp_repos
#   Enable the default SIMP repositories
#
#   * Has no effect if ``enable_simp_local_repos`` is not set
#   * Sets the system up to point to your SIMP servers (``servers`` option) for
#     the OS and SIMP updates
#   * This will probably not apply if you are installing SIMP via YUM or
#     r10k/Code Manager
#
#
# @param enable_os_repos
#   Enable the SIMP OS update repositories
#
#   * Has no effect if ``enable_simp_local_repos`` is not set
#   * Used the ``servers`` option to determine the source of the repositories
#   * This will probably not apply if you are installing SIMP via YUM or
#     r10k/Code Manager
#
# @param servers
#   The FQDN or IP of the yum server to which to connect for SIMP updates
#
#   * Has no effect if ``enable_simp_repos`` is not set
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
#   A specially crafted string that handles GPG URL creation
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
#   A specially crafted string that handles GPG URL creation
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
class simp::yum (
  Boolean                                              $enable_auto_updates        = true,
  Boolean                                              $enable_simp_local_repos    = false,
  Boolean                                              $enable_simp_internet_repos = false,
  String                                               $simp_version               = simp_version(),
  Boolean                                              $enable_simp_repos          = true,
  Boolean                                              $enable_os_repos            = true,
  Optional[Simplib::Netlist]                           $servers                    = undef,
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $os_update_url              = "https://YUM_SERVER/yum/${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}/Updates",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $os_gpg_url                 = '',
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $simp_update_url            = "https://YUM_SERVER/yum/SIMP/${facts['architecture']}",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $simp_gpg_url               = ''
){
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

  if $enable_auto_updates == true {
    include '::simp::yum::schedule'
  }
  else {
    class { 'simp::yum::schedule':
      enable => $enable_auto_updates
    }
  }

  if $enable_simp_local_repos {
    class { 'simp::yum::repo::simp_local':
      servers           => $servers,
      enable_simp_repos => $enable_simp_repos,
      enable_os_repos   => $enable_os_repos,
      os_update_url     => $os_update_url,
      os_gpg_url        => $os_gpg_url,
      simp_update_url   => $simp_update_url,
      simp_gpg_url      => $simp_gpg_url
    }
  }

  if $enable_simp_internet_repos {
    class { 'simp::yum::repo::simp_internet':
      simp_version => $simp_version
    }
  }
}
