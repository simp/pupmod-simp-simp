# Manage resources related to the `root` user
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
# @param password
#  Set the `root` user's password to this value
#
#  * If a recognized password hash, will pass along the value unoutched
#  * If a `String`, will hash the password using the algorithm specified in
#    `$password_hash`
#
# @param password_hash
#   The algorithm to use when hashing a plain text password
#
# @param shell
#   The shell to use for the `root` user
#
# @param home
#   The home directory of the `root` user
#
class simp::root_user (
  Boolean                           $manage_perms  = true,
  Boolean                           $manage_user   = true,
  Boolean                           $manage_group  = true,
  Optional[String[1]]               $password      = undef,
  Enum['MD5', 'SHA-256', 'SHA-512'] $password_hash = 'SHA-512',
  Stdlib::Absolutepath              $shell         = '/bin/bash',
  Stdlib::Absolutepath              $home          = '/root'
){

  simplib::assert_metadata( $module_name )

  if $manage_perms {
    file { $home:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0550'
    }
  }

  if $manage_user {
    case $password {
      undef:   { $_password = undef }
      default: {
        if $password =~ Simplib::ShadowPass {
          $_password = Sensitive($password)
        }
        else {
          $_salt     = fqdn_rand_string(16, '', 'root_user')
          $_password = Sensitive(pw_hash($password, $password_hash, $_salt))
        }
      }
    }

    user { 'root':
      ensure     => 'present',
      uid        => '0',
      gid        => '0',
      allowdupe  => false,
      home       => $home,
      shell      => $shell,
      membership => 'minimum',
      forcelocal => true,
      password   => $_password,
    }
  }

  if $manage_group {
    group { 'root':
      ensure          => 'present',
      gid             => '0',
      allowdupe       => false,
      auth_membership => true,
      forcelocal      => true,
      members         => ['root']
    }
  }
}
