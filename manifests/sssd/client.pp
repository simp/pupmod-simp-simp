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
  $use_ldap = defined('$::use_ldap') ? { true => $::use_ldap, default => hiera('use_ldap',true) }
){
  if $use_ldap {
    # We include these here because, without a domain, SSSD should not be
    # running and will, in fact, complain if you attempt to run without a
    # domain.
    include '::sssd'

    include '::sssd::service::nss'
    include '::sssd::service::pam'

    sssd::domain { 'LDAP':
      description       => 'LDAP Users domain',
      id_provider       => 'ldap',
      auth_provider     => 'ldap',
      chpass_provider   => 'ldap',
      # This needs to change in SIMP 6!
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
