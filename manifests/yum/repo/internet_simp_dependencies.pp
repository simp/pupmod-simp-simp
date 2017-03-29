# Configure yum to use the internet public repository for SIMP dependencies
#
# @param simp_release_slug
#   The unique release "slug" of SIMP for the target release
#   (e.g., '6_X', '6_X_Alpha').
#
#   * Defaults to the version of the **puppet server**
#
class simp::yum::repo::internet_simp_dependencies (
  Variant[String,Undef] $simp_release_slug = undef,
){
  $_release_slug = simp::yum::repo::sanitize_simp_release_slug( $simp_release_slug )

  $_dependency_gpg_keys = [
    'https://raw.githubusercontent.com/NationalSecurityAgency/SIMP/master/GPGKEYS/RPM-GPG-KEY-SIMP',
    'https://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
    'https://yum.puppetlabs.com/RPM-GPG-KEY-puppet',
    'https://apt.postgresql.org/pub/repos/yum/RPM-GPG-KEY-PGDG-94',
    'https://getfedora.org/static/352C64E5.txt'
  ]

  yumrepo { "simp-project_${_release_slug}_Dependencies":
    baseurl         => "https://packagecloud.io/simp-project/${_release_slug}_Dependencies/el/\$releasever/\$basearch",
    descr           => 'Dependencies for the SIMP project',
    enabled         => 1,
    enablegroups    => 0,
    gpgcheck        => 1,
    gpgkey          => join($_dependency_gpg_keys,"\n   "),
    sslverify       => 0,
    keepalive       => 0,
    metadata_expire => 3600
  }
}
