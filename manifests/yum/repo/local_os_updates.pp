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
#  @example Describing a single server by FQDN
#    # When classified to an CentOS 7 x86_64 host, this creates an os_updates
#    # yumrepo with the `baseurl` "https://yum.test.simp/yum/CentOS/7/x86_64/Updates"
#    simp::yum::repo::local_os_updates {
#      servers => ['yum.test.simp']
#    }
#
#  @example Describing a several servers  with FQDN and full url.
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
# @param relative_gpgkey_path
#   The relative path to the yum server to the GPGKEYS. It defaults to where both
#   the ISO and smp-gpgkey rpm will install them: SIMP/GPGKEYS
#   This parameter has no effect if the gpgkey parameter is set.
#
# @param baseurl
#   This parameter only works on EL7 systems.
#   The URL for this repository. Set this to absent to remove it from the file completely.
#   Set this parameter directly to completely skip all automated URL logic.
#   files for non-simp repos.
#
# @param gpgkey
#   The URL for the GPG key with which packages from this repository are signed.
#   Set this parameter directly to completely skip default URL/path logic.
class simp::yum::repo::local_os_updates (
  Array[Simp::HostOrURL] $servers,
  Boolean                $enable_repo        = true,
  Simp::Urls             $extra_gpgkey_urls  = [],
  String[1]              $relative_repo_path = "${facts['os']['name']}/${facts['os']['release']['major']}/${facts['os']['architecture']}",
  String[1]              $relative_gpgkey_path = 'SIMP/GPGKEYS',
  Optional[String[1]]    $baseurl            = undef,
  Optional[String[1]]    $gpgkey             = simp::yum::repo::gpgkey_string(
      $servers,
      simp::yum::repo::gpgkeys::os_updates(),
      $relative_gpgkey_path,
      $extra_gpgkey_urls
  )
){
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })
  $_enable_repo    = $enable_repo ? { true => 1, default => 0 }

  if $facts['os']['release']['major'] > '7' {

    if $baseurl {
      $_os_updates_url = "${baseurl}/BaseOS"
    } else {
      $_os_updates_url = simp::yum::repo::baseurl_string($servers, "${relative_repo_path}/BaseOS")
    }
    yumrepo { 'local_baseos':
      baseurl             => $_os_updates_url,
      descr               => "${facts['os']['name']} ${facts['os']['release']['major']} ${facts['os']['architecture']} base packages and updates",
      enabled             => $_enable_repo,
      enablegroups        => 1,
      gpgcheck            => 1,
      gpgkey              => $gpgkey,
      sslverify           => 0,
      keepalive           => 0,
      metadata_expire     => 3600,
      tag                 => 'firstrun',
      skip_if_unavailable => 1
    }

    if $baseurl {
      $_os_appstream_repo = "${baseurl}/AppStream"
    } else {
      $_os_appstream_repo = simp::yum::repo::baseurl_string($servers, "${relative_repo_path}/AppStream")
    }
    yumrepo { 'local_appstream':
      baseurl             => $_os_appstream_repo,
      descr               => "${facts['os']['name']} ${facts['os']['release']['major']} ${facts['os']['architecture']} app stream packages",
      enabled             => $_enable_repo,
      enablegroups        => 1,
      gpgcheck            => 1,
      gpgkey              => $gpgkey,
      sslverify           => 0,
      keepalive           => 0,
      metadata_expire     => 3600,
      tag                 => 'firstrun',
      skip_if_unavailable => 1
    }

  } else {

    if $baseurl {
      $_baseurl = $baseurl
    } else {
      $_baseurl = simp::yum::repo::baseurl_string($servers, "${relative_repo_path}/Updates")
    }

    yumrepo { 'os_updates':
      baseurl             => $_baseurl,
      descr               => "All ${facts['os']['name']} ${facts['os']['release']['major']} ${facts['os']['architecture']} base packages and updates",
      enabled             => $_enable_repo,
      enablegroups        => 0,
      gpgcheck            => 1,
      gpgkey              => $gpgkey,
      sslverify           => 0,
      keepalive           => 0,
      metadata_expire     => 3600,
      tag                 => 'firstrun',
      skip_if_unavailable => 1
    }
  }
}
