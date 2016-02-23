# == Class: simp::rsyslog::stock::log_server::forward
#
# Set this appropriately if you're forwarding your syslog data to somewhere
# else.
#
# Define for adding fowarding hosts to the log server.
#
# DO NOT make forward_hosts the local log host, this will cause all kinds of
# problems with looping logs and eat your disks.
#
# Note: This will forward *all* logs to the named hosts.
#
# == Parameters
#
# [*forward_hosts*]
#   Type: Array
#     The hosts to which to forward the logs.
#     Be sure to append the port to the host if you wish to send to an
#     alternate port.
#
# [*failover_forward_hosts*]
#   Type: Array
#   Default: []
#     If present, the listed systems will be used as failover servers for the
#     forwarded records.
#
# [*log_transport*]
#   Type: One of ['tcp','udp','relp']
#   The transport to pass the data across. Make sure it stays lower case.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::rsyslog::stock::log_server::forward (
  $forward_hosts,
  $failover_forward_hosts = [],
  $log_transport = 'tcp'
) {
  validate_net_list($forward_hosts)
  if !empty($failover_forward_hosts) { validate_net_list($failover_forward_hosts) }
  validate_array_member($log_transport,['tcp','udp','relp'])

  compliance_map()

  include '::rsyslog'

  rsyslog::rule::remote { 'all_forward':
    rule      => '*.*',
    dest      => $forward_hosts,
    dest_type => $log_transport
  }
}
