# Configure yum to use a (simp-managed) OS Updates repository
#
# Generally, this is used by the ISO installation.
#
# * By default, baseurl and GPG key URLs will work with repositories managed
#   with ``simp::server::yum``.
#
# * Multiple yum servers and arbitrary URLs are accepted; see the ``servers``
#   parameter for details.
#
# * For more complex scenarios, create a site-specific profile and use the native
#   `yumrepo` type directly.
#
#  @example Describing a single server by FQDN
#    # When classified to an CentOS 6 x86_64 host, this creates an os_updates
#    # yumrepo with the ``baseurl`` "https://yum.test.simp/yum/CentOS/6/x86_64/Updates"
#    simp::yum::repo::os_updates_local {
#      servers => ['yum.test.simp']
#    }
#
#  @example Describing a single server by FQDN
#    # When classified to an CentOS 6 x86_64 host, this creates an os_updates
#    # yumrepo with a 3-entry ``baseurl`` and a 3-entry ``gpgkey``
#    simp::yum::repo::os_updates_local {
#      servers => [
#        'yum.test.simp',
#        'yum2.test.simp',
#        'https://yum.updates.url/full/path/to/repo/c6-64-u'
#      ],
#      extra_gpgkey_urls => [
#        'https://yum.updates.url/full/path/to/repo/c6-64-u/RPM-GPG-KEY-CentOS-6'
#      ]
#    }
#
# @param servers
#   An Array of FQDNs, IPs, or URLs containing the yum server(s) to use.
#
#   * An FQDN or IP will be assumed to host it yum repository and GPG keys at
#     the URLs established by ``simp::server::yum``.
#
#   * A URL will be used as-is, and should point directly to its yum repository.
#
# @param enable_repo
#   Enables or disables the Yum repo
#
# @param extra_gpgkey_urls
#   An optional Array of Urls to include additional GPG key files
#
class simp::yum::repo::local_os_updates (
  Array[Simp::HostOrURL]   $servers,
  Boolean                  $enable_repo       = true,
  Simp::Urls               $extra_gpgkey_urls = [],
){

  simplib::assert_metadata( $module_name )

  $_repo_base = "${facts['os']['name']}/${facts['os']['release']['major']}/${facts['architecture']}"

  $_enable_repo    = $enable_repo ? { true => 1, default => 0 }
  $_baseurl_string = simp::yum::repo::baseurl_string($servers, "${_repo_base}/Updates")
  $_gpgkeys_string = simp::yum::repo::gpgkey_string(
    $servers,
    simp::yum::repo::gpgkeys::os_updates(),
    $_repo_base,
    $extra_gpgkey_urls
  )

  yumrepo { 'os_updates':
    baseurl         => $_baseurl_string,
    descr           => "All ${facts['os']['name']} ${facts['os']['release']['major']} ${facts['architecture']} base packages and updates",
    enabled         => $_enable_repo,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => $_gpgkeys_string,
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => 3600,
    tag             => 'firstrun'
  }
}
