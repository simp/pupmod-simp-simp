# This class removes packages that the STIG recommends should be absent on all systems.
#
# It is executed in the the simp_finalize stage of the catalog compilation
# If the package is managed in another part of the catalog it will issue
# a warning.
#
# The knockout prefix can be used to remove any of the packages from the list if it is needed.
#
# @param $packages
#   A Hash of packages derived from the STIG that should not exist on the system.
#
# @param $enable_warning
#   If true a warning will be issued if the package is managed in an earlier part of the
#   catalog.
#
class simp::stig_packages::ensure_absent(
  Hash    $packages       = {},
  Boolean $enable_warning = true
){

  $packages.each |String $package, Optional[Hash] $opts| {
    if defined(Package[$package]) {
      if $enable_warning {
        warning("The STIG recommends package ${package} not be installed. Use of this package must be documented in mitigation report.")
      }
    }
    else {
      if $opts.is_a(Hash) {
        $args = $opts + { 'ensure' => 'absent' }
      }
      else  {
        $args = { 'ensure' => 'absent' }
      }
      package { $package:
        * => $args
      }
    }
  }
}
