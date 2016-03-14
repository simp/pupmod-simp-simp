# == Class: simp::rsyslog::stock::log_server
#
# This class provides a general purpose log server suitable for cenralized logging.
#
# It is highly recommended that you look to use the Logstash module at this point.
#
# WARNING: This is meant to be called through rsyslog::stock. Please do not use
# standalone!
#
# The following must be set fpr the node that will be your rsyslog server
# in hiera for this to work properly:
#
# ---
# rsyslog::global::tls_tcpserver: true
#
# The following are optional for legacy, unencrypted connections.
# rsyslog::global::tcpserver: true
# rsyslog::global::udpserver: true
# rsyslog::global::udpServerAddress: '0.0.0.0'
#
# == Parameters
#
# [*client_nets*]
# Type: Array of networks
# Default: hiera('client_nets')
#   The client networks to which to allow access to the rsyslog service.
#
# [*rotate_period*]
# Type: One of 'daily', 'weekly', 'monthly', or 'yearly'
# Default: 'weekly'
#   The log rotate period.
#
# [*rotate*]
# Type: Integer
# Default: 12
#   How many rotated logs to preserve. 3 months by default.
#
# [*size*]
# Type: Logrotate compatible size value
# Default: None
#   The maximum size of a log file. $rotate_period will be ignored if
#   this is specified.
#
# [*server_conf*]
# Type: String
# Default: ''
#   If set, Add the contained rsyslog configuration to the system
#   instead of the default in this module. The purpose of this is to
#   provide a destination rule set for all logs coming into the
#   server.
#
# [*use_iptables*]
# Type: Boolean
# Default: true
#   Whether or not to use IPTables to restrict access to the system.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::rsyslog::stock::log_server (
  $client_nets = defined('$::client_nets') ? { true  => $::client_nets, default =>  hiera('client_nets') },
  $rotate_period = 'weekly',
  $rotate = '12',
  $security_relevant_logs = $::simp::rsyslog::stock::security_relevant_logs,
  $server_conf = '',
  $size = '',
  $use_default_sudosh_rules = true,
  $use_default_httpd_rules = true,
  $use_default_dhcpd_rules = true,
  $use_default_puppet_agent_rules = true,
  $use_default_puppet_master_rules = true,
  $use_default_audit_rules = true,
  $use_default_slapd_rules = true,
  $use_default_kern_rules = true,
  $use_default_security_relevant_logs = true,
  $use_default_message_rules = true,
  $use_default_mail_rules = true,
  $use_default_cron_rules = true,
  $use_default_emerg_rules = true,
  $use_default_spool_rules = true,
  $use_default_boot_rules = true,
  $use_iptables = defined('$::use_iptables') ? { true  => $::use_iptables, default =>  hiera('use_iptables') }
) {
  include '::rsyslog'
  include '::rsyslog::server'

  assert_private()

  validate_array_member($rotate_period,['daily','weekly','monthly','yearly'])
  validate_bool($use_iptables)
  validate_string($server_conf)
  validate_integer($rotate)
  validate_net_list($client_nets)

  compliance_map()

  # Now, since this is a log server, we'll probably want to run logrotate once
  # per hour to make sure we don't eat up all of our disk space.
  file { '/etc/cron.hourly/logrotate':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/rsyslog/etc/cron.hourly/logrotate'
  }

  # With large files, you can run into a situation where two runs of
  # logrotate attempt to rotate the same file. This is set to prevent
  # that from occuring.
  file { [
    '/etc/cron.daily/logrotate',
    '/etc/cron.monthly/logrotate',
    '/etc/cron.yearly/logrotate'
  ]:
    ensure => 'absent'
  }

  # Don't forget the logrotate rule!
  logrotate::add { 'remote_hosts':
    log_files     => [ '/var/log/hosts/*/*.log' ],
    missingok     => true,
    size          => $size,
    rotate_period => $rotate_period,
    rotate        => $rotate,
    lastaction    => '/usr/sbin/service rsyslog restart > /dev/null 2>&1 || true'
  }

  if empty($server_conf) {
    $file_base = '/var/log/hosts/%HOSTNAME%'
    rsyslog::template::string { 'sudosh_template':            string => "${file_base}/sudosh.log"}
    rsyslog::template::string { 'httpd_template':             string => "${file_base}/httpd.log"}
    rsyslog::template::string { 'dhcpd_template':             string => "${file_base}/dhcpd.log"}
    rsyslog::template::string { 'puppet_agent_err_template':  string => "${file_base}/puppet-agent-err.log"}
    rsyslog::template::string { 'puppet_agent_template':      string => "${file_base}/puppet-agent.log"}
    rsyslog::template::string { 'puppet_master_err_template': string => "${file_base}/puppet-master-err.log"}
    rsyslog::template::string { 'puppet_master_template':     string => "${file_base}/puppet-master.log"}
    rsyslog::template::string { 'audit_template':             string => "${file_base}/audit.log"}
    rsyslog::template::string { 'slapd_audit_template':       string => "${file_base}/slapd_audit.log"}
    rsyslog::template::string { 'iptables_template':          string => "${file_base}/iptables.log"}
    rsyslog::template::string { 'secure_template':            string => "${file_base}/secure.log"}
    rsyslog::template::string { 'messages_template':          string => "${file_base}/messages.log"}
    rsyslog::template::string { 'maillog_template':           string => "${file_base}/maillog.log"}
    rsyslog::template::string { 'cron_template':              string => "${file_base}/cron.log"}
    rsyslog::template::string { 'spooler_template':           string => "${file_base}/spooler.log"}
    rsyslog::template::string { 'boot_template':              string => "${file_base}/boot.log"}

    if $use_default_sudosh_rules {
      rsyslog::rule::local { '0_default_sudosh':
        rule            => 'if ($programname == \'sudosh\') then',
        dyna_file       => 'sudosh_template',
        stop_processing => true
      }
    }
    if $use_default_httpd_rules {
      rsyslog::rule::local { '0_default_httpd':
        rule            => 'if ($programname == \'httpd\') then',
        dyna_file       => 'httpd_template',
        stop_processing => true
      }
    }
    if $use_default_dhcpd_rules {
      rsyslog::rule::local { '0_default_dhcpd':
        rule      => 'if ($programname == \'dhcpd\') then',
        dyna_file => 'dhcpd_template'
      }
    }
    if $use_default_puppet_agent_rules {
      rsyslog::rule::local { '0_default_puppet_agent_error':
        rule            => 'if ($programname == \'puppet-agent\' and $syslogseverity-text == \'err\') then',
        dyna_file       => 'puppet_agent_err_template',
        stop_processing => true
      }
      rsyslog::rule::local { '0_default_puppet_agent':
        rule            => 'if ($programname == \'puppet-agent\') then',
        dyna_file       => 'puppet_agent_template',
        stop_processing => true
      }
    }
    if $use_default_puppet_master_rules {
      rsyslog::rule::local { '0_default_puppet_master_error':
        rule            => 'if ($programname == \'puppet-master\' and $syslogseverity-text == \'err\') then',
        dyna_file       => 'puppet_master_err_template',
        stop_processing => true
      }
      rsyslog::rule::local { '0_default_puppet_master':
        rule            => 'if ($programname == \'puppet-master\') then',
        dyna_file       => 'puppet_master_template',
        stop_processing => true
      }
    }
    if $use_default_audit_rules {
      rsyslog::rule::local { '0_default_audit':
        rule            => 'if ($programname == \'audispd\' or $syslogtag == \'tag_audit_log:\') then',
        dyna_file       => 'audit_template',
        stop_processing => true
      }
    }
    if $use_default_slapd_rules {
      rsyslog::rule::local { '0_default_slapd_audit':
        rule            => 'if ($programname == \'slapd_audit\') then',
        dyna_file       => 'slapd_audit_template',
        stop_processing => true
      }
    }
    if $use_default_kern_rules {
      rsyslog::rule::local { '0_default_kern':
        rule            => 'if ($syslogfacility-text == \'kern\' and $msg startswith \'IPT:\') then',
        dyna_file       => 'iptables_template',
        stop_processing => true
      }
    }
    if $use_default_security_relevant_logs {
      rsyslog::rule::local { '0_default_security_relevant_logs':
        rule            => $security_relevant_logs,
        dyna_file       => 'secure_template',
        stop_processing => true
      }
    }
    if $use_default_message_rules {
      rsyslog::rule::local { '0_default_message':
        rule      => '*.info;mail.none;authpriv.none;cron.none;local6.none;local5.none',
        dyna_file => 'messages_template'
      }
    }
    if $use_default_mail_rules {
      rsyslog::rule::local { '0_default_mail':
        rule      => 'mail.*',
        dyna_file => 'maillog_template'
      }
    }
    if $use_default_cron_rules {
      rsyslog::rule::local { '0_default_cron':
        rule      => 'cron.*',
        dyna_file => 'cron_template'
      }
    }
    if $use_default_emerg_rules {
      rsyslog::rule::console { '0_default_emerg':
        rule  => '*.emerg',
        users => ['*']
      }
    }
    if $use_default_spool_rules {
      rsyslog::rule::local { '0_default_spool':
        rule      => 'uucp,news.crit',
        dyna_file => 'spooler_template'
      }
    }
    if $use_default_boot_rules {
      rsyslog::rule::local { '0_default_boot':
        rule      => 'local7.*',
        dyna_file => 'boot_template'
      }
    }
  }
  else {
    rsyslog::rule::local { '0_default':
      rule => $server_conf,
    }
  }
}
