# Manage resources related to the root user
#
# @params manage_perms
#   Ensure that /root has restricted permissions and proper SELinux
#   contexts.
#
# @params manage_user
#   Ensure the root user has appropriate UIDs and groups, etc
#
# @params manage_group
#  Ensure the root group has appropriate UIDs, etc
#
class simp::root_user (
  Boolean $manage_perms = true,
  Boolean $manage_user  = true,
  Boolean $manage_group = true
){
  if $manage_perms {
    file { '/root':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0700'
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
      groups     => [ 'bin', 'daemon', 'sys', 'adm', 'disk', 'wheel' ],
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
