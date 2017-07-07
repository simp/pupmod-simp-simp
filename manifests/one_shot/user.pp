# NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Configure a 'stand alone' system user
#
# @param enable
#   Enable the one_shot capabilities
#
# @param username
#   The username to use for remote access
#
# @param password
#   The password for the user in passwd-compatible salted hash form
#
# @param home
#   The full path to the user's home directory
#
# @param uid
#   The UID of the user
#
# @param gid
#   The GID of the user
#
# @param ssh_authorized_key
#   The SSH public key for the user
#
#   * See the native ``ssh_authorized_key`` resource definition for details
#
# @param ssh_authorized_key_type
#   The SSH public key type
#
#   * See the native ``ssh_authorized_key`` resource definition for details
#
# @param sudo_users
#   The users that the ``username`` user may escalate to
#
# @param passwordless_sudo
#   Enable passwordless sudo for the user
#
# @param sudo_commands
#   The commands that the ``username`` user is allowed to execute via sudo as one
#   of the allowed users
#
# @param allowed_from
#   The ``pam_access`` compatible locations that the user will be logging in
#   from
#
#   * Set to ``['ALL']`` to allow from any location
class simp::one_shot::user (
  Boolean             $enable                  = $simp::one_shot::enable_user,
  String              $username                = $simp::one_shot::user_name,
  Optional[String]    $password                = $simp::one_shot::user_password,
  Pattern['^/']       $home                    = $simp::one_shot::user_home,
  Integer             $uid                     = $simp::one_shot::user_uid,
  Integer             $gid                     = $simp::one_shot::user_gid,
  Optional[String[1]] $ssh_authorized_key      = $simp::one_shot::user_ssh_authorized_key,
  String[1]           $ssh_authorized_key_type = $simp::one_shot::user_ssh_authorized_key_type,
  String              $sudo_users              = $simp::one_shot::user_sudo_users,
  Boolean             $passwordless_sudo       = $simp::one_shot::user_passwordless_sudo,
  Array[String]       $sudo_commands           = $simp::one_shot::user_sudo_commands,
  Array[String]       $allowed_from            = $simp::one_shot::user_allowed_from
) {
  assert_private()

  $_ensure = $enable ? {
    true    => 'present',
    default => 'absent'
  }

  if $enable {
    file { $home:
      owner   => $username,
      group   => $username,
      mode    => '0640',
      seltype => 'user_home_dir_t'
    }

    pam::access::rule { "allow_${username}":
      users   => [$username],
      origins => ['LOCAL'] + $allowed_from,
      comment => 'Default Temp Local User'
    }

    sudo::user_specification { $username:
      user_list => [$username],
      runas     => $sudo_users,
      cmnd      => $sudo_commands,
      passwd    => $passwordless_sudo
    }
  }

  group { $username:
    ensure => $_ensure,
    gid    => $gid
  }

  user { $username:
    ensure     => $_ensure,
    password   => $password,
    comment    => 'SIMP Standalone User',
    forcelocal => true,
    uid        => $uid,
    gid        => $gid,
    home       => $home,
    managehome => true
  }

  ssh_authorized_key { $username:
    ensure => $_ensure,
    key    => $ssh_authorized_key,
    type   => $ssh_authorized_key_type,
    user   => $username
  }

  if !$enable {
    User[$username] -> Group[$username]
  }
}
