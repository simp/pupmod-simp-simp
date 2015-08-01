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
  $log_servers = hiera('log_servers',[]),
  $security_relevant_logs = $::simp::rsyslog::stock::security_relevant_logs
){
  include '::simp::rsyslog::stock'

  if !empty($log_servers) {
    # Remote rules come before everything else so that we don't lose anything.
    rsyslog::rule::remote { 'simp_stock_remote':
      rule      => $security_relevant_logs,
      dest      => $log_servers,
      dest_type => 'tcp'
    }
  }
}
