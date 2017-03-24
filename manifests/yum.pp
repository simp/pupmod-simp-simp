# Set up the ``/etc/yum`` directory, and ensures that ``yum-skip-broken`` is
# installed.
#
# @param auto_update
#   Enable the automatic yum cron job
#
# @param simp_version
#   The version of SIMP that should be used if pointing to Internet
#   repositories
#
#   * Defaults to the version of SIMP that the **puppet server** is running
#
# @param internet_simp_repos
#   Point your system at all public repositories that are required for a SIMP
#   installation
#
#   * Requires Internet connectivity and a willingness to pull packages from
#     these public repositories
#
# @param local_repo_servers
#   The FQDN or IP of the yum server to which to connect for SIMP updates
#
# @param local_simp_repos
#   Enable the default local SIMP repositories
#
#   * Has no effect if ``local_repo_servers`` is not specified
#   * Sets the system up to point to your SIMP servers (``servers`` option) for
#     the OS and SIMP updates
#   * This will probably not apply if you are installing SIMP via YUM or
#     r10k/Code Manager
#
# @param local_os_repos
#   Enable the default local SIMP OS update repositories
#
#   * Has no effect if ``local_repo_servers`` is not specified
#   * Used the ``servers`` option to determine the source of the repositories
#   * This will probably not apply if you are installing SIMP via YUM or
#     r10k/Code Manager
#
# @param local_simp_update_url
#   A specially crafted string that handles the case where you want to pass in
#   multiple yum servers
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
# @param local_simp_gpg_url
#   A specially crafted string that handles GPG URL creation
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
# @param local_os_update_url
#   A specially crafted string that handles the case where you want to pass in
#   multiple yum servers
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
#   * This is not ideal but there is no way to know exactly how you wish to
#     structure your repositories if you deviate from the base
#
# @param local_os_gpg_url
#   A specially crafted string that handles GPG URL creation
#
#   * The string ``YUM_SERVER`` (all caps) will be replaced with the various
#     ``$servers`` entries appropriately
#
class simp::yum (
  Boolean                                              $auto_update           = true,
  String                                               $simp_version          = simp_version(),
  Boolean                                              $internet_simp_repos   = false,
  Optional[Simplib::Netlist]                           $local_repo_servers    = undef,
  Boolean                                              $local_simp_repos      = false,
  Boolean                                              $local_os_repos        = false,
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $local_simp_update_url = "https://YUM_SERVER/yum/SIMP/${facts['architecture']}",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $local_simp_gpg_url    = '',
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $local_os_update_url   = "https://YUM_SERVER/yum/${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}/Updates",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $local_os_gpg_url      = ''
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

  if $auto_update {
    include '::simp::yum::schedule'
  }
  else {
    class { 'simp::yum::schedule':
      enable => $auto_update
    }
  }

  if ($local_simp_repos or $local_os_repos) and !($local_repo_servers) {
    fail('You must specify `local_repo_servers` if you enable `local_simp_repos` or `local_os_repos`')
  }

  if $local_simp_repos or $local_os_repos {
    class { 'simp::yum::repo::simp_local':
      servers           => $local_repo_servers,
      enable_simp_repos => $local_simp_repos,
      enable_os_repos   => $local_os_repos,
      os_update_url     => $local_os_update_url,
      os_gpg_url        => $local_os_gpg_url,
      simp_update_url   => $local_simp_update_url,
      simp_gpg_url      => $local_simp_gpg_url
    }
  }

  if $internet_simp_repos {
    class { 'simp::yum::repo::simp_internet':
      simp_version => $simp_version
    }
  }
}
