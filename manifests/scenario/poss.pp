# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# The 'Puppet Open Source Software' Scenario
#
# This provides a *minimal* system that connects to a SIMP Puppet server.
#
# This class *does not* provide security for a system but it designed to simply
# allow you to connect to the Puppet server and run puppet as a client.
#
# This class requires no additional configuration to function.
#
# @param puppet_server_hosts_entry
#   Add a ``host`` entry for the Puppet server to the catalog
#
#   * This has no effect if the ``$server_facts`` Hash is not populated
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::scenario::poss (
  Boolean $puppet_server_hosts_entry  = $::simp::puppet_server_hosts_entry
) inherits ::simp {

  assert_private()

  if $puppet_server_hosts_entry {
    if $server_facts and $server_facts['servername'] and $server_facts['serverip'] {
      $_pserver_alias = split($server_facts['servername'],'.')[0]

      host { $server_facts['servername']:
        ensure       => 'present',
        host_aliases => $_pserver_alias,
        ip           => $server_facts['serverip']
      }
    }
  }
}
