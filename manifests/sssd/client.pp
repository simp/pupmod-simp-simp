# @summary Set up an SSSD client based on the normal SIMP parameters
#
# This should work for most out-of-the-box installations. Otherwise, it serves
# as an example of what you can do to make it work for your environment.
#
# @param local_domain
#   Configure the 'LOCAL' domain
#
#   To use the local domain you must include 'LOCAL'  in sssd::domains via hiera
#
# @param local_domain_options
#   A Hash of options to pass directly into the `sssd::domain` defined type
#
# @param ldap_domain
#   Configure the LDAP domain
#
#   To Enable the LDAP domain you must include 'LDAP' sssd::domains via hiera
#
# @param ldap_domain_options
#   A Hash of options to pass directly into the `sssd::domain` defined type
#
# @param ldap_server_type
#   The type of LDAP server that the system is communicating with
#
#   * This mainly matters for password policy details but may increase in scope
#     in the future
#
#   * Use `389ds` for servers that are 'Netscape compatible'. This includes
#     FreeIPA, Red Hat Directory Server, and other Netscape DS-derived systems
#   * Use `plain` for servers that are 'regular LDAP' like OpenLDAP
#
# @param ldap_provider_options
#   A Hash of options to pass directly into the `sssd::provider::ldap` defined type
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
# @param autofs
#   Deprecated
#
# @param sudo
#   Deprecated
#
# @param ssh
#   Deprecated
#
# @author https://github.com/simp/pupmod-simp-simp/graphs/contributors
#
class simp::sssd::client (
  Boolean               $local_domain,
  Hash                  $local_domain_options  = {},
  Boolean               $ldap_domain           = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Hash                  $ldap_domain_options   = {},
  Enum['plain','389ds'] $ldap_server_type,
  Hash                  $ldap_provider_options = {},
  Boolean               $autofs                = true, #deprecated
  Boolean               $sudo                  = true, #deprecated
  Boolean               $ssh                   = true, #deprecated
  Boolean               $enumerate_users       = false,
  Boolean               $cache_credentials     = true,
  Integer               $min_id                = 500
){

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  include 'sssd'

  if $local_domain {
    $_local_domain_defaults = {
      'description' => 'LOCAL Users Domain',
      'min_id'      => $min_id
    }

    sssd::domain { 'LOCAL':
      access_provider   => 'permit',
      enumerate         => false,
      cache_credentials => false,
      id_provider       => 'files',
      *                 => $_local_domain_defaults + $local_domain_options
    }
  }

  if $ldap_domain {
    $_ldap_domain_defaults = {
      'description' => 'LOCAL Users Domain',
      'min_id'      => $min_id
    }

    sssd::domain { 'LDAP':
      id_provider       => 'ldap',
      enumerate         => $enumerate_users,
      cache_credentials => $cache_credentials,
      *                 => $_ldap_domain_defaults + $ldap_domain_options
    }

    $_ldap_provider_defaults = {
      'ldap_default_authtok_type' => 'password',
      'ldap_user_gecos'           => 'displayName'
    }

    if $ldap_server_type in ['389ds'] {
      $_ldap_server_type_defaults = {
        'ldap_account_expire_policy' => 'ipa',
        'ldap_user_ssh_public_key'   => 'nsSshPublicKey'
      }
    }
    elsif $ldap_server_type in ['plain'] {
      $_ldap_server_type_defaults = {
        'ldap_account_expire_policy' => 'shadow',
        'ldap_user_ssh_public_key'   => 'sshPublicKey'
      }
    }

    sssd::provider::ldap { 'LDAP':
      * => $_ldap_provider_defaults + $_ldap_server_type_defaults + $ldap_provider_options
    }
  }
}
