# Manage the content of ``/etc/rc.d/rc.local``
#
# By default, this class will disable the file altogether
#
# @param content
#   Set to ``disable`` to disable the file completely
#
#   * Any other value will be written to the file after an optional management
#     banner
#
# @param shell
#   The shell to use to execute the ``rc.local`` file
#
# @param management_comment
#   Adds a 'managed by Puppet' comment to the top of the file
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::rc_local (
  String               $content            = 'disable',
  Stdlib::Absolutepath $shell              = '/bin/bash',
  Boolean              $management_comment = true
) {

  simplib::assert_metadata( $module_name )


  $_default_header = "#!${shell}\n"
  $_managed_header = "${_default_header}#\n# This file managed by Puppet, manual changes will be erased!\n"

  if $management_comment {
    $_full_header = $_managed_header
  }
  else {
    $_full_header = $_default_header
  }

  if $content == 'disable' {
    $_content = "${_full_header}# This file Disabled via Puppet"
  }
  else {
    $_content = "${_full_header}${content}"
  }

  file { '/etc/rc.d':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  }

  file { '/etc/rc.local':
    ensure => 'link',
    target => '/etc/rc.d/rc.local'
  }

  file { '/etc/rc.d/rc.local':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => $_content
  }
}
