# @summary Configure yum to use the internet public repository for SIMP
#
# @param simp_repos_package
#   Name of the SIMP yum repository package.  This package provides
#   yum repository files for SIMP Puppet modules and their dependencies.
#
# @param simp_repos_package_url
#   URL to the SIMP yum repository package
#
# @param package_ensure
#   The ``$ensure`` status of ``$simp_repos_package``.
#
# @param simp_release_version
#
#  The Major(X), Minor(Y), or Patch(Z) release of SIMP you want.
#
#  * The format is 'X', 'X.Y', 'X.Y.Z', or 'X.Y.Z-iteration. For example,
#    '6', '6.5', '6.5.0', or '6.5.0-0'.
#  * Setting this to a 'X' will install the latest release for that
#    SIMP Major version and grab updates for all future minor and patch
#    releases in that Major version of SIMP. This is the appropriate setting
#    if you want all SIMP releases as they are tested and released.
#  * Setting this to 'X.Y' will install the latest X.Y release and grab updates
#    for all future patches to that X.Y version, but never update to the next
#    Minor version. This is the appropriate setting if you want a specific Minor
#    version of SIMP, but don't want to install new Minor version.
#  * Setting this to 'X.Y.Z' or 'X.Y.Z-iteration' will install that specific
#    SIMP release and never grab any updates. This is the appropriate setting,
#    along with `$simp_release_type = 'releases'`, if you want only a specific
#    release of SIMP, and no future updates.
#  * When not set, this class will attempt to detect the version of SIMP installed
#    on the system and fail if the version cannot be detected.
#
# @param simp_release_type
#
#   Type of release you want:
#
#   * 'releases': Packages from fully tested SIMP releases. This is the
#     recommended setting.
#   * 'rolling': Packages that have not yet made it into a SIMP release,
#     but have been tested and released individually with confidence.
#   * 'unstable/6': Packages in the unstable repository for SIMP 6.
#     This is extremely dangerous and not recommended for production
#     environments.
#
class simp::yum::repo::internet_simp(
  String[1]               $simp_repos_package     = 'simp-release-community',
  String[1]               $simp_repos_package_url = "https://download.simp-project.com/${simp_repos_package}.rpm",
  Simp::PackageEnsure     $package_ensure         = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  String                  $simp_release_type      = 'releases',
  Optional[Simp::Version] $simp_release_version   = undef
){

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  package { $simp_repos_package:
    source => $simp_repos_package_url,
    ensure => $package_ensure
  }

  if $package_ensure == 'absent' {
    file { ['/etc/yum/vars/simprelease', '/etc/yum/vars/simpreleasetype']:
      ensure => absent,
      before => Package[$simp_repos_package]
    }
  }
  else {
    $_simp_release_version = simp::yum::repo::simp_release_version($simp_release_version)
    file { '/etc/yum/vars/simprelease':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "${_simp_release_version}\n",
      require => Package[$simp_repos_package]  # will create directory
    }

    file { '/etc/yum/vars/simpreleasetype':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "${simp_release_type}\n",
      require => Package[$simp_repos_package]  # will create directory
    }
  }
}
