# This class will be removed in a future version of SIMP.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::base_services {

  simplib::assert_metadata( $module_name )

  # to ensure api compatbility
  include 'simp::base_apps'

}
