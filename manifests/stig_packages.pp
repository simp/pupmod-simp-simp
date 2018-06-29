# This class installs or removes packages that are explicitly called
# out in the STIG to be installed or removed.
#
# This will run classes in the simp_finalize stage to be as sure as possible
# that all other package resources are defined in the catalog.  If
# a resource is determined to already exist in the catalog
# a warning  will be displayed.  These warnings can be disabled in hiera.
#
# Hash is of the form:
# package name => hash of package options
# 'default'    => hash of options to apply to all packages
#                 in the hash.
# The ensure setting for the packages will be set by
# from the hash they are in.
#
# @param absent_packages
#   A hash of packes that  should be ensured absent.
# @param  install_packages
#   A hash of packages to ensure installed
# @param mode
#   If set to enforcing then package resources
#   are created.  If set to warning a message
#   is display for each resource that would have
#   been created.
#
# @param $enable_warnings
#   If set to false then no warnings are displayed if a package
#   resource exists in the catalog that differs from the setting
#   in the list.
class simp::stig_packages(
  Hash                        $absent_packages,
  Hash                        $install_packages,
  Enum['warning','enforcing'] $mode               = 'warning',
  Boolean                     $enable_warnings    = true
) {


    stig_packages{ 'stig_packages':
      remove  => $absent_packages,
      add     => $install_packages,
      warning => $enable_warnings,
      mode    => $mode
    }
}
