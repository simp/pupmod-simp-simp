# == Class: simp::freeradius::stock_ldap
#
# Provide a default configuration of FreeRadius that matches the one from Red
# Hat that includes the ability to work properly with the default SIMP LDAP
# configuration.
#
# For this configuration to work, you will need to add 'objectClass:
# radiusprofile' to any account that you wish to use with this configuration.
#
# The following LDIF will do this for you:
#  dn: uid=<username>,ou=<your>,ou=<base>,ou=<dn>
#  changetype: modify
#  add: objectClass
#  objectClass: radiusprofile
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::freeradius::stock_ldap {
  include '::simp::freeradius::stock'
  include '::freeradius::modules::ldap'
}
