# This class sets up an SSSD client based on the normal SIMP parameters
#
# This should work for most out-of-the-box installations. Otherwise, it serves
# as an example of what you can do to make it work for your environment.
#
# Since this class calls several defines, you will want to use a resource
# collector to enhance/override the resource declarations.
#
# If you don't specify either ``$ldap_domain`` or ``$local_domain``, this class
# will not execute anything on the client.
#
# @see https://docs.puppetlabs.com/puppet/latest/reference/lang_resources_advanced.html#amending-attributes-with-a-collector Amending Attributes With a Collector
#
# @param ldap_domain
#   Enable the LDAP hooks via SSSD
#
# @param local_domain
#   Enable the 'LOCAL' domain
#
# @param autofs
#   Enable ``autofs`` support in SSSD
#
# @param sudo
#   Enable ``sudo`` support in SSSD
#
# @param ssh
#   Enable ``ssh`` support in SSSD
#
# @param enumerate_users
#   Have SSSD list and cache all the users that it can find on the remote system
#
#   * Take care that you don't overwhelm your LDAP server if you enable this
#
# @param cache_credentials
#   Have SSSD cache the credentials of users that login to the system
#
# @param min_id
#   The lowest user ID that SSSD should recognize from the remote server
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::sssd::client (
  Boolean $ldap_domain       = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean $local_domain      = true,
  Boolean $autofs            = true,
  Boolean $sudo              = true,
  Boolean $ssh               = true,
  Boolean $enumerate_users   = false,
  Boolean $cache_credentials = true,
  Integer $min_id            = 500
){

  simplib::assert_metadata( $module_name )

  if $ldap_domain or $local_domain {
    include '::sssd'
    include '::sssd::service::nss'
    include '::sssd::service::pam'

    if $autofs { include '::sssd::service::autofs' }
    if $sudo { include '::sssd::service::sudo' }
    if $ssh { include '::sssd::service::ssh' }

    if $local_domain {
      sssd::domain { 'LOCAL':
        description       => 'LOCAL Users Domain',
        id_provider       => 'local',
        auth_provider     => 'local',
        access_provider   => 'permit',
        min_id            => $min_id,
        # These don't make sense on the local domain
        enumerate         => false,
        cache_credentials => false
      }
    }

    if $ldap_domain {
      sssd::domain { 'LDAP':
        description       => 'LDAP Users Domain',
        id_provider       => 'ldap',
        auth_provider     => 'ldap',
        chpass_provider   => 'ldap',
        access_provider   => 'ldap',
        sudo_provider     => 'ldap',
        autofs_provider   => 'ldap',
        min_id            => $min_id,
        enumerate         => $enumerate_users,
        cache_credentials => $cache_credentials
      }

      sssd::provider::ldap { 'LDAP':
        ldap_default_authtok_type => 'password',
        ldap_user_gecos           => 'dn'
      }
    }
  }
}
