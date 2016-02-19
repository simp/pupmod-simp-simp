# == Class: simp::server
#
# This class sets up a SIMP server in such a way that it will be ready to serve
# configuration data appropriately to your clients.
#
# == Parameters
#
# [*allow_simp_user*]
# Type: Boolean
# Default: true
#   If true, ensure that the 'simp' user can login to the system.
#
# [*enable_puppetdb*]
# Type: Boolean
# Default: false
#   If true, set this master to point at a PuppetDB server.
#
#   NOTE: You must set the appropriate parameters for puppetdb::master::config
#   in either Hiera or your ENC for this to work as you would expect.
#
#   If your server is also your PuppetDB host, it might *just work*, but don't
#   count on it.
#
# [*enable_rsync_shares*]
# Type: Boolean
# Default: true
#   If true, enable all of the default SIMP rsync shares. You should not
#   disable this unless you have specific needs and understand the dependencies
#   on the various rsync shares.
#
# == Authors
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::server (
  $allow_simp_user = true,
  $enable_puppetdb = false,
  $enable_rsync_shares = true,
){
  include '::pupmod::master'

  validate_bool($allow_simp_user)
  validate_bool($enable_puppetdb)
  validate_bool($enable_rsync_shares)

  compliance_map()

  if $enable_puppetdb {
    include 'puppetdb::master::config'
  }

  if $allow_simp_user {
    pam::access::manage { 'allow_simp':
      users   => 'simp',
      origins => ['ALL'],
      comment => 'The SIMP user, used to remotely login to the system in the case of a lockout.'
    }

    sudo::user_specification { 'default_simp':
      user_list => 'simp',
      runas     => 'root',
      cmnd      => ['/bin/su root', '/bin/su - root']
    }
  }
  if $enable_rsync_shares {
    include '::simp::server::rsync_shares'
  }
}
