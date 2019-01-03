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
  Boolean                                         $manage_perms = true,
  Boolean                                         $manage_user  = true,
  Boolean                                         $manage_group = true,
  Variant[Undef, String, Pattern[/^\$\d[ay]?\$/]] $password     = undef,
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
      undef:                { $_password = undef }
      /^\$6\$/:             { $_password = Sensitive($password) }
      /^\$[125]{1}[ay]?\$/: { fail('Error: You cannot use MD5, Blowfish, or SHA256 hashing algorithms for the user password. Please hash with SHA512.') }
      default:              {
        $_salt     = fqdn_rand_string(16)
        $_password = Sensitive(pw_hash($password, 'SHA-512', $_salt))
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
