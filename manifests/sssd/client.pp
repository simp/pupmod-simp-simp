# This class sets up an SSSD client based on the normal SIMP parameters.  This
# should work for most out-of-the-box installations. Otherwise, it serves as an
# example of what you can do to make it work for your environment.
#
# Since this class calls several defines, you will want to use a resource
# collector to enhance/override the resource declarations.
#
# See: https://docs.puppetlabs.com/puppet/latest/reference/lang_resources_advanced.html#amending-attributes-with-a-collector
#
# @param ldap
#   If true, enable the LDAP hooks via SSSD. If false, makes this class a noop.
#
# @param use_autofs
#   If true, enable autofs support in SSSD.
#
# @param use_sudo
#   If true, enable sudo support in SSSD.
#
# @param use_ssh
#   If true, enable ssh support in SSSD.
#
# @param enumerate_users
#   If true, have SSSD list and cache all the users that it can find on the
#   LDAP server.
#
# @param min_id
#   The lowest ID number that SSSD should recognize from the remote server.
#   This will be raised to '1000' in a future release.
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::sssd::client (
  Boolean $ldap            = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean $use_autofs      = true,
  Boolean $use_sudo        = true,
  Boolean $use_ssh         = true,
  Boolean $enumerate_users = false,
  Integer $min_id          = 501
){

  if $ldap {
    # We include these here because, without a domain, SSSD should not be
    # running and will, in fact, complain if you attempt to run without a
    # domain.
    include '::sssd'

    include '::sssd::service::nss'
    include '::sssd::service::pam'

    if $use_autofs { include '::sssd::service::autofs' }
    if $use_sudo { include '::sssd::service::sudo' }
    if $use_ssh { include '::sssd::service::ssh' }

    sssd::domain { 'LDAP':
      description       => 'LDAP Users Domain',
      id_provider       => 'ldap',
      auth_provider     => 'ldap',
      chpass_provider   => 'ldap',
      access_provider   => 'ldap',
      sudo_provider     => 'ldap',
      autofs_provider   => 'ldap',
      # This needs to change in SIMP 6!
      min_id            => $min_id,
      enumerate         => $enumerate_users,
      cache_credentials => true
    }

    sssd::provider::ldap { 'LDAP':
      ldap_default_authtok_type => 'password',
      ldap_user_gecos           => 'dn'
    }
  }
}
