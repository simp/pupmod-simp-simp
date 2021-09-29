# @summary Set up the local SIMP repositiories for network-isolated
#   environments.
#
# Generally, this is used by the ISO installation's SIMP agents.
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
#    # When classified to an CentOS 7 x86_64 host, this creates a `simp`
#    # yumrepo with the ``baseurl`` "https://yum.test.simp/yum/CentOS/7/x86_64/Updates"
#    simp::yum::repo::simp_local {
#      servers => ['yum.test.simp']
#    }
#
#  @example Describing a single server by FQDN
#    # When classified to an CentOS 7 x86_64 host, this creates a `simp`
#    # yumrepo with a 3-entry ``baseurl`` and a multiple ``gpgkey`` entries
#    simp::yum::repo::simp_local {
#      servers => [
#        'yum.test.simp',
#        'yum2.test.simp',
#        'https://yum.updates.url/full/path/to/repo/c6-64-u'
#      ],
#    }
#
#  @example Describing a single server with specific URLs
#    # This explicitly sets the `baseurl` and `gpgkey` keys in simp.repo
#    # (This overrides all other parameters and automagic URL logic.)
#    simp::yum::repo::local_simp {
#      baseurl => 'https://yum.test.simp/yum/SIMP/CentOS/8/x86_64',
#      gpgkey  => [
#        'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-8',
#        'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-PGDG-94',
#        'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-PGDG-96',
#        'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP',
#        'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP-6',
#        'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet',
#        'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs',
#      ].join("\n    ")
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
#   In simp repos
#   This parameter has no effect if the `baseurl` parameter is set directly.
#
# @param relative_gpgkey_path
#   The relative path to the GPGKEYS for the SIMP repo.  It defaults
#   to the directory where simp-gpgkeys installs the gpgkeys.
#
# @param baseurl
#   The URL for this repository. Set this to absent to remove it from the file completely.
#   Set this parameter directly to completely skip all automated URL logic.
#
# @param gpgkey
#   The URL for the GPG key with which packages from this repository are signed.
#   Set this parameter directly to completely skip default URL/path logic.
class simp::yum::repo::local_simp (
  Array[Simp::HostOrURL] $servers,
  Boolean                $enable_repo           = true,
  Simp::Urls             $extra_gpgkey_urls     = [],
  String[1]              $relative_repo_path    = "SIMP/${facts['os'][name]}/${facts['os']['release']['major']}",
  String[1]              $relative_gpgkey_path  = "SIMP/GPGKEYS",
  Optional[String[1]]    $baseurl               = simp::yum::repo::baseurl_string($servers, "${relative_repo_path}/${facts['architecture']}"),
  Optional[String[1]]    $gpgkey                = simp::yum::repo::gpgkey_string(
    $servers,
    simp::yum::repo::gpgkeys::simp(),
    $relative_gpgkey_path,
    $extra_gpgkey_urls
  )
){
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  $_enable_repo    = $enable_repo ? { true => 1, default => 0 }

  $_common_attrs = {
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

  $_descr_base = "SIMP ${facts['os']['name']} ${facts['os']['release']['major']} ${facts['architecture']}"

  if $facts['package_provider'] == 'dnf' {
    yumrepo { 'simp':
      baseurl => "${baseurl}/simp",
      descr   => "${_descr_base} product packages",
      *       => $_common_attrs
    }

    yumrepo { 'simp-puppet':
      baseurl => "${baseurl}/puppet",
      descr   => "${_descr_base} Puppet packages",
      *       => $_common_attrs
    }

    yumrepo { 'simp-vendor-extras':
      baseurl => "${baseurl}/extras",
      descr   => "${_descr_base} Vendor extras required for correct application",
      *       => $_common_attrs
    }

    yumrepo { 'simp-vendor-powertools':
      baseurl => "${baseurl}/PowerTools",
      descr   => "${_descr_base} Vendor power tools required for correct application",
      *       => $_common_attrs
    }

    yumrepo { 'simp-epel':
      baseurl => "${baseurl}/epel",
      descr   => "${_descr_base} required packages from EPEL",
      *       => $_common_attrs
    }

    yumrepo { 'simp-postgresql':
      baseurl => "${baseurl}/postgresql",
      descr   => "${_descr_base} postgresql packages",
      *       => $_common_attrs
    }

    yumrepo { 'simp-epel-modular':
      baseurl => "${baseurl}/epel-modular",
      descr   => "${_descr_base} EPEL Modular packages",
      *       => $_common_attrs
    }
  }
  else {
    yumrepo { 'simp':
      baseurl => "${baseurl}",
      descr   => "${_descr_base} product packages",
      *       => $_common_attrs
    }
  }
}
