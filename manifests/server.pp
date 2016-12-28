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
  Boolean $allow_simp_user     = true,
  Boolean $enable_rsync_shares = true,
){
  if $allow_simp_user {
    pam::access::rule { 'allow_simp':
      users   => ['simp'],
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
