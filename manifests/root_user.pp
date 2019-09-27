# @summary Manage resources related to the `root` user
#
# @param manage_perms
#   Ensure that `$home` has restricted permissions and proper SELinux contexts.
#
# @param manage_user
#   Ensure the `root` user has appropriate UIDs and groups, etc
#
# @param manage_group
#  Ensure the `root` group has appropriate UIDs, etc
#
# @param hashed_password
#   Validate the correctness of the password hash and then pass it through to
#   the `User` resource for `root`
#
# @param password
#  Pass this through untouched to the `User` resource for `root`
#
#  * Please use `$hashed_password` if possible
#
# @param username
#   The username of the `root` user
#
# @param uid
#   The UID of the `root` user
#
# @param gid
#   The GID of the `root` user
#
# @param shell
#   The shell to use for the `root` user
#
# @param home
#   The home directory of the `root` user
#
class simp::root_user (
  Boolean                       $manage_perms    = true,
  Boolean                       $manage_user     = true,
  Boolean                       $manage_group    = true,
  Optional[Simplib::ShadowPass] $hashed_password = undef,
  Optional[String[1]]           $password        = undef,
  String[1]                     $username        = 'root',
  Integer[0]                    $uid             = 0,
  Integer[0]                    $gid             = 0,
  Stdlib::Absolutepath          $shell           = '/bin/bash',
  Stdlib::Absolutepath          $home            = "/${username}"
){

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if $manage_perms {
    file { $home:
      ensure => 'directory',
      owner  => $username,
      group  => $username,
      mode   => '0550'
    }
  }

  if $manage_user {

    if $password and $hashed_password {
      fail('Error: You cannot specify both "$password" and "$hashed_password"')
    }

    if $password {
      $_password = Sensitive($password)
    }
    elsif $hashed_password {
      $_password = Sensitive($hashed_password)
    }
    else {
      $_password = undef
    }

    user { $username:
      ensure     => 'present',
      uid        => $uid,
      gid        => $gid,
      allowdupe  => false,
      home       => $home,
      shell      => $shell,
      membership => 'minimum',
      forcelocal => true,
      password   => $_password
    }
  }

  if $manage_group {
    group { $username:
      ensure          => 'present',
      gid             => $gid,
      allowdupe       => false,
      auth_membership => true,
      forcelocal      => true,
      members         => [$username]
    }
  }
}
