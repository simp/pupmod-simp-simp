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
# @param forward_hosts
#     The hosts to which to forward the logs.
#     Be sure to append the port to the host if you wish to send to an
#     alternate port.
#
# @param failover_forward_hosts
#     If present, the listed systems will be used as failover servers for the
#     forwarded records.
#
# @param log_transport
#   The transport to pass the data across. Make sure it stays lower case.
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::rsyslog::stock::log_server::forward (
  Array[String]            $forward_hosts,
  Array                    $failover_forward_hosts = [],
  Enum['tcp','udp','relp'] $log_transport          = 'tcp'
) {
  validate_net_list($forward_hosts)
  if !empty($failover_forward_hosts) { validate_net_list($failover_forward_hosts) }

  include '::rsyslog'

  rsyslog::rule::remote { 'all_forward':
    rule      => '*.*',
    dest      => $forward_hosts,
    dest_type => $log_transport
  }
}
