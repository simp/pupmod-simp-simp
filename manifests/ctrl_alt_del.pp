# Manage the state of pressing ``ctrl-alt-del``
#
# @param enable
#   Allow ``ctrl-alt-del`` to restart the system
#
# @param log
#   Instead of just disabling the command, set the system up to write a log
#   entry when the key combination is pressed
#
# @param log_users
#   Record all logged in users in the log message
#
# @param facility
#   The ``syslog`` facility to use for the log message
#
# @param severity
#   The ``syslog`` severity to use for the log message
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::ctrl_alt_del (
  Boolean                   $enable    = false,
  Boolean                   $log       = true,
  Boolean                   $log_users = true,
  Simplib::Syslog::Facility $facility  = 'local6',
  Simplib::Syslog::Severity $severity  = 'warning'
) {

  simplib::assert_metadata( $module_name )

  if 'systemd' in $facts['init_systems'] {
    $_logger = '/bin/echo -n'
  }
  else {
    $_logger = "/bin/logger -p ${facility}.${severity}"
  }

  if $log {
    if $log_users {
      $_log_cmnd = "/bin/sh -c \"${_logger} 'Ctrl-Alt-Del detected - Logged in users:' `/usr/bin/who | /bin/cut -f1 -d' ' | /bin/sort -u | /usr/bin/tr '\\n' ' '`\""
    }
    else {
      $_log_cmnd = "/bin/sh -c \"${_logger} 'Ctrl-Alt-Del detected'\""
    }
  }

  if 'systemd' in $facts['init_systems'] {
    if $enable {
      file { '/etc/systemd/system/ctrl-alt-del.target': ensure => 'absent' }
      file { '/etc/systemd/system/ctrl-alt-del-capture.service': ensure => 'absent' }
    }
    else {
      if $log {
        file { '/etc/systemd/system/ctrl-alt-del.target':
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          content => file("${module_name}/etc/systemd/system/ctrl-alt-del.target")
        }

        file { '/etc/systemd/system/ctrl-alt-del-capture.service':
          ensure  => 'file',
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          content => template("${module_name}/etc/systemd/system/ctrl-alt-del-capture.service.erb")
        }
      }
      else {
        file { '/etc/systemd/system/ctrl-alt-del.target':
          ensure => 'symlink',
          target => '/dev/null',
          force  => true
        }

        file { '/etc/systemd/system/ctrl-alt-del-capture.service': ensure => 'absent' }
      }

      File['/etc/systemd/system/ctrl-alt-del.target'] ~> Exec['ctrl_alt_del_systemd_reexec']
      File['/etc/systemd/system/ctrl-alt-del-capture.service'] ~> Exec['ctrl_alt_del_systemd_reexec']
    }

    exec { 'ctrl_alt_del_systemd_reexec':
      refreshonly => true,
      command     => '/bin/systemctl daemon-reexec'
    }
  }
  elsif 'upstart' in $facts['init_systems'] {
    include '::upstart'

    if $enable {
      upstart::job { 'control-alt-delete':
        main_process => '/sbin/shutdown -r now "Control-Alt-Delete pressed"',
        start_on     => 'control-alt-delete',
        description  => 'Logs that Ctrl-Alt-Del was pressed without rebooting the system.'
      }
    }
    else {
      if $log {
        upstart::job { 'control-alt-delete':
          main_process => $_log_cmnd,
          start_on     => 'control-alt-delete',
          description  => 'Logs that Ctrl-Alt-Del was pressed without rebooting the system.'
        }
      }
      else {
        upstart::job { 'control-alt-delete':
          main_process => '/bin/true',
          start_on     => 'control-alt-delete',
          description  => 'Logs that Ctrl-Alt-Del was pressed without rebooting the system.'
        }
      }
    }
  }
  else {
    fail('Could not find a supported init system')
  }
}
