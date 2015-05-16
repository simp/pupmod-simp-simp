# == Class: simp::rsyslog::stock::log_server::forward
#
# Set this appropriately if you're forwarding your syslog data to somewhere
# else.
#
# Define for adding a fowarding host to the log server.
#
# DO NOT make forward_host the local log host, this will cause all kinds of
# problems with looping logs and eat your disks.
#
# Note: This will forward *all* logs to the named host.
#
# == Parameters
#
# [*forward_host*]
#   The host to which to forward the logs.
#
# [*forward_port*]
#   The port to which to forward the logs.
#
# [*log_transport*]
#   The transport to pass the data across. Make sure it stays lower case.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::rsyslog::stock::log_server::forward (
  $forward_host,
  $forward_port = '6514',
  $log_transport = 'tcp'
) {
  include 'rsyslog'

  rsyslog::add_conf { 'remote':
    content => $log_transport ? {
      'tcp'   => "*.* \t\t @@${forward_host}:${forward_port}",
      'relp'  => "*.* \t\t :omrelp:${forward_host}:${forward_port}",
      default => "*.* \t\t @${forward_host}:${forward_port}"
    }
  }

  validate_net_list($forward_host)
  validate_integer($forward_port)
  validate_array_member($log_transport,['tcp','udp','relp'])
}
