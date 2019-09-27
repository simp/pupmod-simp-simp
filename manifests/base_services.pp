# @summary Deprecated - This class will be removed in a future version of SIMP.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::base_services {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  # to ensure api compatbility
  include 'simp::base_apps'

}
