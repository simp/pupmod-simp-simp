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
# @param pam
#   Enable SIMP management of the PAM stack
#
# @param clamav
#   Enable SIMP management of Antivirus
#
# @param selinux
#   Enable SIMP management of SELinux
#
# @param auditd
#   Enable SIMP management of auditing
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::server (
  Boolean $allow_simp_user = false,
  Boolean $pam             = simplib::lookup('simp_options::pam', { 'default_value' => false }),
  Boolean $clamav          = simplib::lookup('simp_options::clamav', { 'default_value' => false }),
  Boolean $selinux         = simplib::lookup('simp_options::selinux', { 'default_value' => false }),
  Boolean $auditd          = simplib::lookup('simp_options::auditd', { 'default_value' => false })
) {

  include '::aide'
  include '::at'
  include '::chkrootkit'
  include '::cron'
  include '::incron'
  include '::issue'
  include '::nsswitch'
  include '::ntpd'
  include '::pam::access'
  include '::pam::wheel'
  include '::pupmod'
  include '::resolv'
  include '::ssh'
  include '::sudosh'
  include '::svckill'
  include '::swap'
  include '::timezone'
  include '::tuned'
  include '::useradd'
  include '::simp::admin'
  include '::simp::base_apps'
  include '::simp::base_services'
  include '::simp::kmod_blacklist'
  include '::simp::mountpoints'
  include '::simp::server::rsync_shares'
  include '::simp::sysctl'

  if $clamav  { include '::clamav' }
  if $selinux { include '::selinux' }
  if $auditd  { include '::auditd' }

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
