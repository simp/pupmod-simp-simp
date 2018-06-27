# This class installs or removes packages that are required by the
# STIG.
# It is executed in the the simp_finalize stage of the catalog compilation to
# ensure that if the package is explicity installed or removed earlier
# the resource will not be created.
#
# The knockout prefix can be used to remove any of the packages from the list if it is needed.
#
# @params packages
#   a hash of packages with options to be installed
#
# @param package_ensure
#   Ensure mode for the packages, can be set to latest or installed.
#
# @param enable_warning
#   If true a warning message will be issued for each package in the
#   list that is managed in another part of the catalog.
#
class simp::stig_packages::ensure_installed(
  Hash    $packages = {},
  String  $package_ensure  = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  Boolean $enable_warning = false
){

  $packages.each | String $package, Optional[Hash] $opts| {

    if defined(Package[$package]) {
      if  $enable_warning {
        warning("Module ${module_name} is trying to install package ${package} for STIG compliance but the resource is already defined.")
      }
    }
    else {
      $_ensure_installed = $package_ensure ? {
        'latest' => $package_ensure,
        default  => 'installed'
      }
      if $opts.is_a(Hash) {
        $args = $opts + { 'ensure' => $_ensure_installed }
      }
      else  {
        $args = { 'ensure' => $_ensure_installed }
      }
      package { $package:
        * => $args
      }
    }
  }

}
