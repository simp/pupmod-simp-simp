# == Class: simp::sssd::client
#
# This class sets up an SSSD client based on the normal SIMP parameters.  This
# should work for most out-of-the-box installations. Otherwise, it serves as an
# example of what you can do to make it work for your environment.
#
# == Authors
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::sssd::client (
  $use_ldap = hiera('use_ldap',false)
){
  include 'sssd'

  include 'sssd::service::nss'
  include 'sssd::service::pam'

  if $use_ldap {
    sssd::domain { 'LDAP':
      description       => 'LDAP Users domain',
      id_provider       => 'ldap',
      auth_provider     => 'ldap',
      chpass_provider   => 'ldap',
      min_id            => '501',
      enumerate         => true,
      cache_credentials => true
    }

    sssd::provider::ldap { 'LDAP':
      ldap_default_authtok_type => 'password',
      ldap_user_gecos           => 'dn'
    }
  }
}
