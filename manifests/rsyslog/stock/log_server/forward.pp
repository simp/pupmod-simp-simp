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
#   The hosts to which to forward the logs.
#
# [*forward_port*]
#   Type: Port
#   The port to which to forward the logs.
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
  $forward_port = '6514',
  $log_transport = 'tcp'
) {
  validate_array($forward_hosts)
  validate_net_list($forward_hosts)
  validate_integer($forward_port)
  validate_array_member($log_transport,['tcp','udp','relp'])

  include '::rsyslog'

  rsyslog::rule::remote { 'all_forward':
    rule      => '*.*',
    dest      => $forward_hosts,
    dest_type => $log_transport
  }
}
