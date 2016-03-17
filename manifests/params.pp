# == Class: simp::params
#
# A set of defaults for the 'simp' namespace
#
# $use_sssd
# Default: false on EL<7, true otherwise
#   There are issues with nscd and nslcd on EL7+ which can result in users
#   being locked out of the system. SSSD contains a bug which will allow users
#   with a valid SSH key to bypass the password lockout as returned by LDAP but
#   this can be worked around much more easily than the workaround for the nscd
#   issues which significantly weaken your security posture.
class simp::params {
  if $::operatingsystem in ['RedHat','CentOS'] {
    if (versioncmp($::operatingsystemrelease,'6.7') < 0) {
      $_use_sssd = false
      $_use_nscd = true
    }
    else {
      $_use_sssd = true
      $_use_nscd = false
    }

    $use_sssd = defined('$::use_sssd') ? {
      true => $::use_sssd,
      default => hiera('use_sssd',$_use_sssd)
    }

    $use_nscd = defined('$::use_nscd') ? {
      true => $::use_nscd,
      default => hiera('use_nscd',$_use_nscd)
    }
  }
  else {
    fail("${::operatingsystem} not yet supported by ${module_name}")
  }
}
