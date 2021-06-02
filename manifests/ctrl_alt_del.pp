# @summary Manage the state of pressing ``ctrl-alt-del``
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

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if $log {
    if $log_users {
      $_log_cmnd = "/bin/sh -c \"/bin/echo -n 'Ctrl-Alt-Del detected - Logged in users:' `/usr/bin/who | /bin/cut -f1 -d' ' | /bin/sort -u | /usr/bin/tr '\\n' ' '`\""
    }
    else {
      $_log_cmnd = "/bin/sh -c \"/bin/echo -n 'Ctrl-Alt-Del detected'\""
    }
  }

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
