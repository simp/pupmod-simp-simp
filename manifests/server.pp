# Set up a SIMP server in such a way that it will be ready to serve
# configuration data appropriately to your clients.
#
# @param allow_simp_user
#   Ensure that the ``simp`` user can login to the system
#
# @param enable_rsync_shares
#   Enable all of the default SIMP rsync shares
#
#   * You should **not** disable this unless you have specific needs and
#     understand the dependencies on the various rsync shares
#
# @param enable_kickstart
#   Set the system up as a kickstart server
#
# @param enable_ldap
#   Set the system up as an OpenLDAP server
#
# @param enable_yum
#   Set the system up as a YUM server
#
# @param pam
#   Enable SIMP management of the PAM stack
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::server (
  Boolean $allow_simp_user     = false,
  Boolean $enable_rsync_shares = true,
  Boolean $enable_kickstart    = true,
  Boolean $enable_ldap         = true,
  Boolean $enable_yum          = true,
  Boolean $pam                 = simplib::lookup('simp_options::pam', { 'default_value' => false })
) {
  if $enable_rsync_shares { include '::simp::server::rsync_shares' }
  if $enable_kickstart { include '::simp::server::kickstart' }
  if $enable_ldap { include '::simp::server::ldap' }
  if $enable_yum { include '::simp::server::yum' }

  if $allow_simp_user {
    if $pam {
      include '::pam'

      pam::access::rule { 'allow_simp':
        users   => ['simp'],
        origins => ['ALL'],
        comment => 'The SIMP user, used to remotely login to the system in the case of a lockout.'
      }
    }

    sudo::user_specification { 'default_simp':
      user_list => ['simp'],
      runas     => 'root',
      cmnd      => ['/bin/su root', '/bin/su - root']
    }
  }
}
