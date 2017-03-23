# Set up the SIMP public repositories for system use
#
# @param simp_version
#   The version of SIMP that the system is running
#
#   * Defaults to the version of the **puppet server**
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::yum::repo::simp_internet (
  String $simp_version = simp_version()
){
  assert_private()

  $_simp_maj_version = (split($simp_version,'\.'))[0]

  if to_string($_simp_maj_version) == '6' {
    yumrepo { 'simp-project_6_X':
      baseurl         => 'https://packagecloud.io/simp-project/6_X/el/$releasever/$basearch',
      descr           => 'The main SIMP repository',
      enabled         => 1,
      enablegroups    => 0,
      gpgcheck        => 1,
      gpgkey          => 'https://raw.githubusercontent.com/NationalSecurityAgency/SIMP/master/GPGKEYS/RPM-GPG-KEY-SIMP',
      sslverify       => 0,
      keepalive       => 0,
      metadata_expire => 3600
    }

    $_dependency_gpg_keys = [
      'https://raw.githubusercontent.com/NationalSecurityAgency/SIMP/master/GPGKEYS/RPM-GPG-KEY-SIMP',
      'https://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
      'https://yum.puppetlabs.com/RPM-GPG-KEY-puppet',
      'https://apt.postgresql.org/pub/repos/yum/RPM-GPG-KEY-PGDG-94',
      'https://getfedora.org/static/352C64E5.txt'
    ]

    yumrepo { 'simp-project_6_X_Dependencies':
      baseurl         => 'https://packagecloud.io/simp-project/6_X_Dependencies/el/$releasever/$basearch',
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
  else {
    fail("SIMP version ${simp_version} is not supported. Please set `simp::yum::enable_simp_internet_repos` to `false` and try again")
  }
}
