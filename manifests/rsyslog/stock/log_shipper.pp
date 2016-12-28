# This class provides a general purpose log server suitable for local logging.
#
# WARNING: This is meant to be called from rsyslog::stock and should not be
# used stand-alone.
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::rsyslog::stock::log_shipper (
  Array  $log_servers            = simplib::lookup('simp_options::syslog::log_servers', { 'default_value' => [] }),
  Array  $failover_log_servers   = simplib::lookup('simp_options::syslog::failover_log_servers', { 'default_value' => [] }),
  String $security_relevant_logs = $::simp::rsyslog::stock::security_relevant_logs
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
