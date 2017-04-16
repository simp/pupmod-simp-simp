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
# @param auto_fakeca
#   Set up the system so that the FakeCA generates certificates based on the
#   signing of a host's Puppet certificate
#
#   * This triggers in real time based on the creation of a Puppet client
#     certificate which means that it only works on a Puppet CA
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::server (
  Hash[String, Array] $scenario_map,
  Boolean             $allow_simp_user = false,
  Boolean             $pam             = simplib::lookup('simp_options::pam', { 'default_value'     => false }),
  Boolean             $clamav          = simplib::lookup('simp_options::clamav', { 'default_value'  => false }),
  Boolean             $selinux         = simplib::lookup('simp_options::selinux', { 'default_value' => false }),
  Boolean             $auditd          = simplib::lookup('simp_options::auditd', { 'default_value'  => false }),
  String              $scenario        = simplib::lookup('simp::scenario', { 'default_value'        => 'simp' }),
  Array[String]       $classes         = [],
  Boolean             $auto_fakeca     = false
) {

  if $scenario_map.has_key($scenario) {
    include simp::knockout(union($scenario_map[$scenario], $classes))
  }
  else {
    fail("ERROR - Invalid scenario '${scenario}' for the given scenario map.")
  }

  ### DO NOT INCLUDE ANY CLASSES ABOVE THIS LINE ###

  if $clamav  { include '::clamav' }
  if $selinux { include '::selinux' }
  if $auditd  { include '::auditd' }
  if $auto_fakeca { include 'simp::server::auto_fakeca' }

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
