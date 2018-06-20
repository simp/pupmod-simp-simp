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
class simp::root_user (
  Boolean $manage_perms = true,
  Boolean $manage_user  = true,
  Boolean $manage_group = true
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
    user { 'root':
      ensure     => 'present',
      uid        => '0',
      gid        => '0',
      allowdupe  => false,
      home       => '/root',
      shell      => '/bin/bash',
      membership => 'minimum',
      forcelocal => true
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
