# == Class: simp::puppetdb
#
# This class enables a PuppetDB server with defaults set for SIMP
# compatibility.
#
# NOTE: Hiera variables *must* be set appropriately under the puppetdb
# namespace.
#
# == Parameters
#
# [*client_nets*]
#   Type: Array of IP Addresses/Hostnames
#   Default: hiera('client_nets',['127.0.0.1'])
#
#   This is used to allow specific hosts access to PuppetDB. This should be
#   restricted to only those hosts that need to talk to PuppetDB, primarly
#   Puppet Masters.
#
#   Unfortunately, this cannot be set via exported resources since PuppetDB
#   needs to be running prior to exported resources functioning properly. Once
#   PuppetDB is up, then you can switch this to exported resources mode using
#   the *use_exported_resources* variable.
#
# All other parameters are taken directly from puppetdb::server and will be
# collapsed into an embedded Hieradata file when data in modules exists.
#
# == Authors
#
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::puppetdb (
  Array   $client_nets            = defined('$::client_nets') ? { true  => $::client_nets, default =>  hiera('client_nets',['127.0.0.1']) },
  String  $listen_address         = '127.0.0.1',
  Integer $listen_port            = 8138,
  Boolean $open_listen_port       = false,
  Boolean $ssl_deploy_certs       = true,
  Boolean $ssl_set_cert_paths     = true,
  String  $ssl_listen_address     = '0.0.0.0',
  Integer $ssl_listen_port        = 8139,
  Boolean $use_puppet_ssl_certs   = true,
  Boolean $disable_ssl            = false,
  Boolean $manage_package_repo    = false,
  String  $database_password      = passgen('simp_puppetdb'),
  String  $read_database_username = 'simp_puppetdb',
  String  $read_database_password = passgen('simp_read_puppetdb'),
  String  $read_database_name     = 'simp_puppetdb',
  Boolean $read_database_ssl      = true,
  Boolean $manage_firewall        = true,
  Boolean $manage_puppetserver    = true,
  String  $java_max_memory        = '40%',
  String  $java_start_memory      = '',
  String  $java_tmpdir            = '/opt/puppetlabs/puppet/cache/pdb_tmp',
  Boolean $java_heapdump_on_oom   = false,
  Boolean $java_prefer_ipv4       = true,
  Boolean $use_iptables           = defined('$::use_iptables') ? { true  => $::use_iptables, default => hiera('use_iptables', true) }
) {

  validate_net_list($client_nets)
  validate_port($listen_port)
  validate_port($ssl_listen_port)
  validate_absolute_path($java_tmpdir)
  validate_bool($manage_puppetserver)

  $_simp_manage_firewall = ($manage_firewall and $use_iptables)

  $_java_max_memory = inline_template('<% if @java_max_memory[-1].chr == "%" %><%= (@memorysize_mb.to_f * (@java_max_memory[0..-2].to_f/100.0)).round.to_s + "m" %><% else %><%= @java_max_memory %><% end %>')

  if !defined('::puppetdb::java_args') or empty($::puppetdb::java_args) {
    $_java_heapdump_on_oom = $java_heapdump_on_oom ? { true => '-XX:HeapDumpOnOutOfMemoryError', default => '-XX:-HeapDumpOnOutOfMemoryError' }

    if empty($java_start_memory) {
      $_java_start_memory = $_java_max_memory
    }
    else {
      $_java_start_memory = $java_start_memory
    }

    $_java_args = {
      '-Xmx'                        => $_java_max_memory,
      '-Xms'                        => $_java_start_memory,
      $_java_heapdump_on_oom        => '',
      '-Djava.io.tmpdir='           => $java_tmpdir,
      '-Djava.net.preferIPv4Stack=' => bool2str($java_prefer_ipv4)
    }
  }

  else {
    $_java_args = $::puppetdb::java_args
  }

  $_my_defaults = {
    'listen_address'         => $listen_address,
    'listen_port'            => $listen_port,
    'open_listen_port'       => $open_listen_port,
    'ssl_deploy_certs'       => $ssl_deploy_certs,
    'ssl_set_cert_paths'     => $ssl_set_cert_paths,
    'ssl_listen_address'     => $ssl_listen_address,
    'ssl_listen_port'        => $ssl_listen_port,
    'disable_ssl'            => $disable_ssl,
    'manage_package_repo'    => $manage_package_repo,
    'database_password'      => $database_password,
    'read_database_username' => $read_database_username,
    'read_database_password' => $read_database_password,
    'read_database_name'     => $read_database_name,
    'read_database_ssl'      => $read_database_ssl,
    'manage_firewall'        => ($manage_firewall and !($_simp_manage_firewall)),
    'java_args'              => $_java_args
  }

  class { 'puppetdb': * => $_my_defaults }

  include 'puppetdb::master::config'

  file { $java_tmpdir:
    ensure => 'directory',
    owner  => 'puppetdb',
    group  => 'puppetdb',
    mode   => '0640',
    before => Service[$::puppetdb::puppetdb_service]
  }

  if $manage_puppetserver {
    # We will need to restart the puppet master service if certain config
    # files are changed, so here we make sure it's in the catalog.
    include 'pupmod::master::base'
    Class['puppetdb::master::puppetdb_conf'] ~> Class['::pupmod::master::base']
  }

  # We need to do this to make PuppetDB use the system puppet certificates
  if $use_puppet_ssl_certs {
    File<| title == $::puppetdb::ssl_key_path |> {
      content   => undef,
      show_diff => false,
      source    => "file://${facts['puppet_settings']['main']['hostprivkey']}"
    }
    File<| title == $::puppetdb::ssl_cert_path |> {
      content   => undef,
      show_diff => false,
      source    => "file://${facts['puppet_settings']['main']['hostcert']}"
    }
    File<| title == $::puppetdb::ssl_ca_cert_path |> {
      content   => undef,
      show_diff => false,
      source    => "file://${facts['puppet_settings']['main']['localcacert']}"
    }
  }

  # Don't fight with the Puppet firewall module
  if $_simp_manage_firewall {
    include '::iptables'

    iptables::add_tcp_stateful_listen { 'puppetdb':
      dports      => [$::puppetdb::ssl_listen_port],
      client_nets => $client_nets,
      # Need this for the auto-connect test script
      before      => Service[$::puppetdb::puppetdb_service]
    }
  }
}
