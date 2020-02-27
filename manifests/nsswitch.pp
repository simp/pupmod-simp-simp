# @summary A SIMP profile for using the nsswitch module to manage /etc/nsswitch
#
# @param ldap SIMP global catalyst to enable LDAP
# @param sssd SIMP global catalyst to enable sssd
#
# @note  This class uses trinklin/nsswitch module.
#
class simp::nsswitch (
  Hash    $defaults,
  Hash    $sssd_options,
  Hash    $ldap_options,
  Hash    $overrides = {},
  Boolean $ldap = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean $sssd = simplib::lookup('simp_options::sssd', { 'default_value' => false })
) {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  # if we're using sssd, configure as such
  if $sssd {
    $options = $defaults + $sssd_options
  }
  elsif $ldap {
    $options = $defaults + $ldap_options
  }
  else {
    $options = {}
  }

  class { 'nsswitch':
    * => $defaults + $options + $overrides
  }
}
