# @summary Configure yum to use a (SIMP-managed) OS Updates repository for
#   network-isolated environments.
#
# Generally, this is used by the ISO installation's SIMP agents.
#
# * By default, baseurl and GPG key URLs will work with repositories managed
#   with `simp::server::yum`.
#
# * Multiple yum servers and arbitrary URLs are accepted; see the `servers`
#   parameter for details.
#
# * For more complex scenarios, create a site-specific profile and use the native
#   `yumrepo` type directly.
#
#  @example Describing a single server with specific URLs
#    # This explicitly sets the `baseurl` and `gpgkey` keys in os_updates.repo.
#    # (This overrides all other parameters and automagic URL logic.)
#    simp::yum::repo::local_os_updates {
#      baseurl => 'https://yum.test.simp/yum/CentOS/8/x86_64/Updates',
#      gpgkey  => 'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-CentOS-8',
#    }
#
#  @example Describing a single server by FQDN
#    # When classified to an CentOS 7 x86_64 host, this creates an os_updates
#    # yumrepo with the `baseurl` "https://yum.test.simp/yum/CentOS/7/x86_64/Updates"
#    simp::yum::repo::local_os_updates {
#      servers => ['yum.test.simp']
#    }
#
#  @example Describing a single server by FQDN
#    # When classified to an CentOS 7 x86_64 host, this creates an os_updates
#    # yumrepo with a 3-entry `baseurl` and a 3-entry `gpgkey`
#    simp::yum::repo::local_os_updates {
#      servers => [
#        'yum.test.simp',
#        'yum2.test.simp',
#        'https://yum.updates.url/specific/path/to/repo/c7-64-u'
#      ],
#      gpgkey => 'https://yum.updates.url/full/path/to/repo/c6-64-u/RPM-GPG-KEY-CentOS-7',
#    }
#
# @param servers
#   An Array of FQDNs, IPs, or URLs containing the yum server(s) to use.
#
#   * An FQDN or IP will be assumed to host it yum repository and GPG keys at
#     the URLs established by `simp::server::yum`.
#
#   * A URL will be used as-is, and should point directly to its yum repository.
#
#   This parameter has no effect if the `baseurl` parameter is set directly.
#
# @param enable_repo
#   Enables or disables the Yum repo
#
# @param extra_gpgkey_urls
#   An optional Array of Urls to include additional GPG key files.
#   This parameter has no effect if the `gpgkey` parameter is set directly.
#
# @param relative_repo_path
#   The relative path to the yum repo relative to the URL(s) set in `$servers`.
#   This parameter has no effect if the `baseurl` parameter is set directly.
#
# @param baseurl
#   The URL for this repository. Set this to absent to remove it from the file completely.
#   Set this parameter directly to completely skip all automated URL logic.
#
# @param gpgkey
#   The URL for the GPG key with which packages from this repository are signed.
#   Set this parameter directly to completely skip default URL/path logic.
class simp::yum::repo::local_os_updates (
  Array[Simp::HostOrURL] $servers,
  Boolean                $enable_repo        = true,
  Simp::Urls             $extra_gpgkey_urls  = [],
  String[1]              $relative_repo_path = "${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}",
  String[1]              $baseurl            = simp::yum::repo::baseurl_string($servers, "${relative_repo_path}/Updates"),
  String[1]              $gpgkey             = simp::yum::repo::gpgkey_string(
      $servers,
      simp::yum::repo::gpgkeys::os_updates(),
      $relative_repo_path,
      $extra_gpgkey_urls
  )
){
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })
  $_enable_repo    = $enable_repo ? { true => 1, default => 0 }

  yumrepo { 'os_updates':
    baseurl         => $baseurl,
    descr           => "All ${facts['os']['name']} ${facts['os']['release']['major']} ${facts['architecture']} base packages and updates",
    enabled         => $_enable_repo,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => $gpgkey,
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => 3600,
    tag             => 'firstrun'
  }
}
