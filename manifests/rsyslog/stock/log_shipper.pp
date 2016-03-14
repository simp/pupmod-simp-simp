# == Class: simp::rsyslog::stock::log_local
#
# This class provides a general purpose log server suitable for local logging.
#
# WARNING: This is meant to be called from rsyslog::stock and should not be
# used stand-alone.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::rsyslog::stock::log_shipper (
  $log_servers = defined('$::log_servers') ? { true => $::log_servers, default => hiera('log_servers',[]) },
  $failover_log_servers = defined('$::failover_log_servers') ? { true => $::failover_log_servers, default => hiera('failover_log_servers',[]) },
  $security_relevant_logs = $::simp::rsyslog::stock::security_relevant_logs
) {
  assert_private()

  if !empty($log_servers) {
    # Remote rules come before everything else so that we don't lose anything.
    rsyslog::rule::remote { 'simp_stock_remote':
      rule                 => $security_relevant_logs,
      dest                 => $log_servers,
      failover_log_servers => $failover_log_servers,
      dest_type            => 'tcp'
    }
  }
}
