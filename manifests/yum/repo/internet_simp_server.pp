# Configure yum to use the internet public repository for SIMP servers
#
# @note If a system is not intended to be a SIMP server, it probably doesn't need
#       this profile.
#
# @param simp_release_slug
#   The unique release "slug" of SIMP for the target release
#   (e.g., '6_X', '6_X_Alpha').
#
#   * Defaults to the version of the **puppet server**
#
class simp::yum::repo::internet_simp_server (
  Variant[String,Undef] $simp_release_slug = undef,
){

  simplib::assert_metadata( $module_name )

  $_release_slug = simp::yum::repo::sanitize_simp_release_slug( $simp_release_slug )

  $_release = $facts['os']['release']['major']
  $_arch = $facts['architecture']

  yumrepo { "simp-project_${_release_slug}":
    baseurl         => "https://packagecloud.io/simp-project/${_release_slug}/el/${_release}/${_arch}",
    descr           => 'The main SIMP repository',
    enabled         => 1,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => [
      'https://raw.githubusercontent.com/NationalSecurityAgency/SIMP/master/GPGKEYS/RPM-GPG-KEY-SIMP',
      'https://download.simp-project.com/simp/GPGKEYS/RPM-GPG-KEY-SIMP-6'
    ],
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => 3600
  }
}
