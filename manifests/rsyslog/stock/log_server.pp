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
  $client_nets = hiera('client_nets'),
  $rotate_period = 'weekly',
  $rotate = '12',
  $size = '',
  $use_iptables = hiera('use_iptables',true),
  $server_conf = '',
  $security_relevant_logs = $::simp::rsyslog::stock::security_relevant_logs
) {
  include 'rsyslog::stock'

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

  if $use_iptables {
    if $::rsyslog::global::tls_tcpserver {
      iptables::add_tcp_stateful_listen { 'syslog_tls_tcp':
        client_nets => $client_nets,
        dports      => $::rsyslog::global::tls_tcpServerRun
      }
    }
    if $::rsyslog::global::tcpserver {
      iptables::add_tcp_stateful_listen { 'syslog_tcp':
        client_nets => $client_nets,
        dports      => $::rsyslog::global::tcpServerRun
      }
    }
    if $::rsyslog::global::udpserver {
      iptables::add_udp_listen { 'syslog_udp':
        client_nets => $client_nets,
        dports      => $::rsyslog::global::udpServerRun
      }
    }
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
    rsyslog::add_rule { '0_default':
      rule => "
if \$programname == 'sudosh' then \t\t ?sudoshTemplate
&~

if \$programname == 'httpd' then \t\t ?httpdTemplate
&~

if \$programname == 'dhcpd' then \t\t ?dhcpTemplate

if \$programname == 'puppet-agent' and \$syslogseverity-text == 'err' then \t\t ?puppetAgentErrTemplate
if \$programname == 'puppet-agent' then \t\t ?puppetAgentTemplate
&~

if \$programname == 'puppet-master' and \$syslogseverity-text == 'err' then \t\t ?puppetMasterErrTemplate
if \$programname == 'puppet-master' then \t\t ?puppetMasterTemplate
& ~

if \$programname == 'audispd' then \t\t ?auditTemplate
& ~

if \$syslogtag == 'tag_audit_log:' then \t\t ?auditTemplate
& ~

if \$programname == 'slapd_audit' then \t\t ?slapdAuditTemplate
& ~

if \$syslogfacility-text == 'kern' and \$msg startswith 'IPT:' then \t\t ?iptablesTemplate
& ~

${security_relevant_logs} \t\t ?secureTemplate
& ~

*.info;mail.none;authpriv.none;cron.none;local6.none;local5.none \t\t ?messageTemplate
mail.* \t\t ?maillogTemplate
cron.* \t\t ?cronTemplate
*.emerg \t\t ?emergTemplate
uucp,news.crit \t\t ?spoolerTemplate
local7.* \t\t ?bootTemplate
" # --> END RULE
    }
  }
  else {
    rsyslog::add_rule { '0_default': rule => $server_conf }
  }

  $template_base = '/var/log/hosts/%HOSTNAME%'

  rsyslog::add_template { 'auditTemplate':            content => "$template_base/audit.log" }
  rsyslog::add_template { 'bootTemplate':             content => "$template_base/boot.log" }
  rsyslog::add_template { 'cronTemplate':             content => "$template_base/cron.log" }
  rsyslog::add_template { 'dhcpTemplate':             content => "$template_base/dhcpd.log" }
  rsyslog::add_template { 'emergTemplate':            content => "$template_base/*" }
  rsyslog::add_template { 'httpdTemplate':            content => "$template_base/httpd.log" }
  rsyslog::add_template { 'iptablesTemplate':         content => "$template_base/iptables.log" }
  rsyslog::add_template { 'maillogTemplate':          content => "$template_base/maillog.log" }
  rsyslog::add_template { 'messageTemplate':          content => "$template_base/messages.log" }
  rsyslog::add_template { 'puppetAgentErrTemplate':   content => "$template_base/puppet-agent-err.log" }
  rsyslog::add_template { 'puppetAgentTemplate':      content => "$template_base/puppet-agent.log" }
  rsyslog::add_template { 'puppetMasterErrTemplate':  content => "$template_base/puppet-master-err.log" }
  rsyslog::add_template { 'puppetMasterTemplate':     content => "$template_base/puppet-master.log" }
  rsyslog::add_template { 'secureTemplate':           content => "$template_base/secure.log" }
  rsyslog::add_template { 'slapdAuditTemplate':       content => "$template_base/slapd_audit.log" }
  rsyslog::add_template { 'spoolerTemplate':          content => "$template_base/spooler.log" }
  rsyslog::add_template { 'sudoshTemplate':           content => "$template_base/sudosh.log" }

  validate_array_member($rotate_period,['daily','weekly','monthly','yearly'])
  validate_bool($use_iptables)
  validate_string($server_conf)
  validate_integer($rotate)
  validate_net_list($client_nets)
}
