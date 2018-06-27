# This class installs or removes packages that are explicitly called
# out in the STIG to be installed or removed.
#
# This will run classes in the simp_finalize stage to be as sure as possible
# that all other package resources are defined in the catalog.  If
# a resource is determined to already exist in the catalog
# a warning  will be displayed.  These warnings can be disabled in hiera.
#
class simp::stig_packages(
  Hash  $absent_packages,
  Hash  $install_packages
) {

    include simplib::stages
  

    #    class { 'simp::stig_packages::ensure_installed':
    #  stage =>  simp_finalize,
    #}
    #class { 'simp::stig_packages::ensure_absent':
    #  stage =>  simp_finalize,
    #}

    stig_packages{ 'stig_packages':
      remove => $absent_packages,
      add    => $install_packages,
      mode   => 'warning'
    }
}
