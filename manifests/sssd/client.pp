# @summary This class sets up an SSSD client based on the normal SIMP
# parameters.
#
# This should work for most out-of-the-box installations. Otherwise, it serves
# as an example of what you can do to make it work for your environment.
#
# Since this class calls several defines, you will want to use a resource
# collector to enhance/override the resource declarations.
#
# @see https://docs.puppetlabs.com/puppet/latest/reference/lang_resources_advanced.html#amending-attributes-with-a-collector Amending Attributes With a Collector
#
# @param ldap_domain
#   Configure the LDAP domain.  To Enable the LDAP domain you
#   must include 'LDAP' sssd::domains.
#
# @param local_domain
#   Configure the 'LOCAL' domain.  To use the local domain you must include
#   'LOCAL'  in sssd::domains.
#
#  The following settings have no effect on sssd unless the service
#  was included in sssd::services.  Since sssd now includes the service
#  setup automatically if the service is included this is not needed.
# @param autofs
#   Enable ``autofs`` support in SSSD
#   deprecated.  Instead set sssd::services to include 'autofs'.
#
# @param sudo
#   deprecated.  Instead set sssd::services to include 'sudo'
#   Enable ``sudo`` support in SSSD
#
# @param ssh
#   deprecated.  Instead set sssd::services to include 'sudo'
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
# @author https://github.com/simp/pupmod-simp-simp/graphs/contributors
#
class simp::sssd::client (
  Boolean $ldap_domain       = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean $local_domain,     #data in module
  Boolean $autofs            = true, #deprecated
  Boolean $sudo              = true, #deprecated
  Boolean $ssh               = true, #deprecated
  Boolean $enumerate_users   = false,
  Boolean $cache_credentials = true,
  Integer $min_id            = 500
){

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  # Don't attemt to setup sssd in EL7 if a local or ldap domain is not defined.

  if $local_domain or $ldap_domain or versioncmp($facts['os']['release']['major'], '8') >= 0 {

    include 'sssd'

    if $local_domain {

      sssd::domain { 'LOCAL':
        description       => 'LOCAL Users Domain',
        access_provider   => 'permit',
        min_id            => $min_id,
        # These don't make sense on the local domain
        enumerate         => false,
        cache_credentials => false,
        id_provider       => 'files'
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
