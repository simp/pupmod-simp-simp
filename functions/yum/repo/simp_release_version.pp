# Returns the SIMP release version for use in SIMP internet yum repositories.
#
# When `$simp_release_version` is specified, this value is simply returned.
# Otherwise, attempts to determine the SIMP release version automatically.
# When this automatic detection fails or the version is not a released
# version (e.g., Beta version), this function fails.
#
# @param simp_release_version
#   Optional desired SIMP release version.
#
# @return [Simp::Version]
#
function simp::yum::repo::simp_release_version(
  Optional[Simp::Version] $simp_release_version = undef
) {
  if $simp_release_version !~ Undef {
    $_release_version = $simp_release_version
  }
  else {
    $_simp_version = simplib::simp_version()
    if $_simp_version == 'unknown' {
      # We get here if the simp.version file (in /etc/simp or
      # C:/ProgramData/SIMP) is not available or the pupmod-simp-simp
      # RPM is not installed.
      fail('Unable to determine SIMP version automatically. You must configured SIMP version to use in SIMP internet repositories')
    }

    # If the value is the result of "rpm -q --qf '%{VERSION}-%{RELEASE}\n' simp",
    # it will have the dist qualifier (e.g. '.el7') on it.  Need to strip that
    # away.
    $_simp_version_no_dist = inline_template('<%= @_simp_version.gsub(/\.el[0-9]+$/, "") %>')

    if $_simp_version_no_dist =~ Simp::Version {
      $_release_version = $_simp_version_no_dist
    }
    else {
      # This is probably a pre-release testing version of SIMP (e.g., 6.5.0-Alpha)
      # and *NOT* a released version.
      fail("SIMP version ${_simp_version_no_dist} is not a released version. You must configure unstable SIMP internet repositories.")
    }
  }
  $_release_version
}
