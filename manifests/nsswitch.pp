# @summary A SIMP profile for using the nsswitch module to manage /etc/nsswitch
#
# @param defaults
#   A hash of the default nsswitch options to use for all services.
#   These will be overridden by any options specified in sssd_options or overrides.
# @param sssd_options
#   A hash of nsswitch options to use for all services when sssd is enabled.
#   These will be overridden by any options specified in overrides.
# @param overrides
#   A hash of nsswitch options to use for all services that will override any options specified in defaults or sssd_options.
# @param sssd SIMP global catalyst to enable sssd
#
# @note  This class uses trinklin/nsswitch module.
#
class simp::nsswitch (
  Hash    $defaults,
  Hash    $sssd_options,
  Hash    $overrides = {},
  Boolean $sssd = simplib::lookup('simp_options::sssd', { 'default_value' => false })
) {
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  # if we're using sssd, configure as such
  if $sssd {
    $options = $defaults + $sssd_options
  }
  else {
    $options = {}
  }

  class { 'nsswitch':
    * => $defaults + $options + $overrides,
  }
}
