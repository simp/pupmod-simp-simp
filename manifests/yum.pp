# Set up the ``/etc/yum`` directory, and ensures that ``yum-skip-broken`` is
# installed.
#
# @param api_version [SemVer]
#   The API version for this class.
#
# @param servers
#   The FQDN or IP of the yum server to which to connect
#
# @param enable_simp_repos
#   Enable the default SIMP repositories
#
#   * You should probably leave this as is unless you really know what you are
#     doing
#
# @param enable_auto_updates
#   Enable the automatic yum cron job
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
class simp::yum (
  Pattern[/^\d+\.\d+\.\d+$/]                           $api_version         = '1.0.0',
  Optional[Simplib::Netlist]                           $servers             = undef,
  Boolean                                              $enable_simp_repos   = true,
  Boolean                                              $enable_os_repos     = true,
  Boolean                                              $enable_auto_updates = true,
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $os_update_url       = "https://YUM_SERVER/yum/${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}/Updates",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $os_gpg_url          = '',
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl]           $simp_update_url     = "https://YUM_SERVER/yum/SIMP/${facts['architecture']}",
  Variant[Stdlib::HTTPSUrl, Stdlib::HTTPUrl, Enum['']] $simp_gpg_url        = ''
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

  case SemVer($api_version) {
    SemVer[SemVerRange('>=1.0.0 <2.0.0')]: {
      if $servers.is_a(Undef) {
        fail('Parameter `servers` is required for this version of the API.')
      }

      class { simp::yum::api_v1: }
    }
    default: {
      fail("ERROR: Invalid API version for ${name}")
    }
  }
}
