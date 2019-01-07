# Manage resources related to the root user
#
# @param manage_perms
#   Ensure that /root has restricted permissions and proper SELinux
#   contexts.
#
# @param manage_user
#   Ensure the root user has appropriate UIDs and groups, etc
#
# @param manage_group
#  Ensure the root group has appropriate UIDs, etc
#
# @param password
#  Set the root user's password using Puppet
#
class simp::root_user (
  Boolean          $manage_perms = true,
  Boolean          $manage_user  = true,
  Boolean          $manage_group = true,
  Optional[String] $password      = undef,
  Boolean          $hash_password = false,
){

  simplib::assert_metadata( $module_name )

  if $manage_perms {
    file { '/root':
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
        if $hash_password {
          $_salt     = fqdn_rand_string(16, '', 'root_user')
          $_password = Sensitive(pw_hash($password, 'SHA-512', $_salt))
        } else {
          if $password =~ Simplib::ShadowPass {
            $_password = Sensitive($password)
          } else {
            fail('Error: You must either enable the hash_password boolean, or provide a hash value that meets Simplib::ShadowPass standards.')
          }
        }
      }
    }

    user { 'root':
      ensure     => 'present',
      uid        => '0',
      gid        => '0',
      allowdupe  => false,
      home       => '/root',
      shell      => '/bin/bash',
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
