# Configure the system to disconnect from the Puppet server once it has
# successfully run
#
# This should *not* be used as part of the standard SIMP runpuppet
# configuration
#
# @param enable_user
#   Add a one_shot user account that will be able to login to the system
#
# @param user_name
#   The username to use for remote access
#
# @param user_password
#   The password for the user in **passwd-compatible salted hash** form
#
#   * NOTE: Either ``user_password`` or ``user_ssh_public_key`` must be
#     specified
#
# @param user_uid
#   The UID of the user
#
# @param user_gid
#   The GID of the user
#
# @param user_home
#   The full path to the user's home directory
#
# @param user_ssh_authorized_key
#   The SSH authorized key for the user
#
#   * See the native ``ssh_authorized_key`` resource definition for details
#
# @param user_ssh_authorized_key_type
#   The type of the SSH authorized key for the user
#
#   * See the native ``ssh_authorized_key`` resource definition for details
#
# @param user_sudo_users
#   The users that the ``username`` user may escalate to
#
# @param user_sudo_commands
#   The commands that the ``username`` user is allowed to execute via sudo as one
#   of the allowed users
#
# @param user_passwordless_sudo
#   Allow the user to use passwordless ``sudo``
#
#   * If not set, the ``user_password`` must be specified
#
# @param user_allowed_from
#   The ``pam_access`` compatible locations that the user will be logging in
#   from
#
#   * Set to ``['ALL']`` to allow from any location
#
# @param finalize_dry_run
#   Run the finalization script in 'dry run' mode and only print what would
#   have been done
#
# @param finalize_remove_pki
#   Remove the SIMP installed host PKI certificates
#
# @param finalize_remove_puppet
#   Remove the puppet packages from the system during finalization
#
# @param finalize_remove_script
#   Remove the finalization script itself from the system
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::one_shot (
  Boolean             $enable_user                  = true,
  String              $user_name                    = 'simp_one_shot',
  Optional[String[8]] $user_password                = undef,
  Integer             $user_uid                     = 1777,
  Integer             $user_gid                     = $user_uid,
  Pattern['^/']       $user_home                    = "/var/local/${user_name}",
  Optional[String[1]] $user_ssh_authorized_key      = undef,
  String[1]           $user_ssh_authorized_key_type = 'ssh-rsa',
  String              $user_sudo_users              = 'root',
  Boolean             $user_passwordless_sudo       = false,
  Array[String[1]]    $user_sudo_commands           = ['ALL'],
  Array[String[1]]    $user_allowed_from            = ['ALL'],
  Boolean             $finalize_dry_run             = false,
  Boolean             $finalize_remove_pki          = false,
  Boolean             $finalize_remove_puppet       = true,
  Boolean             $finalize_remove_script       = true
) {

  simplib::assert_metadata( $module_name )

  include 'simplib::stages'

  if $enable_user {
    unless ($user_password or $user_ssh_authorized_key) {
      fail("You must specify either 'simp::one_shot::user_password' or 'simp::one_shot::user_ssh_authorized_key'")
    }
  }

  contain 'simp::one_shot::user'

  # Handle VMWare systems on EL6
  if ($facts['virtual'] == 'vmware') and (versioncmp($facts['os']['release']['major'], '6') == 1) {
    service { 'vmtoolsd':
      ensure => 'running',
      enable => true
    }
  }

  # The last of the last
  #
  # This ensures that *any* failures that happen in the previous stages will
  # prevent our finalization code from running
  #
  # It's a best-effort way to ensure that all configuration has been placed
  #
  # The only place where this may have issues is if there are changes that are
  # based on facts that would require an additional run to take effect
  stage { 'simp_one_shot_finalization':
    require => Stage['simp_finalize']
  }

  class { 'simp::one_shot::finalize':
    stage => 'simp_one_shot_finalization'
  }
}
