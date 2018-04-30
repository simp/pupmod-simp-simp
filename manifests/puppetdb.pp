# This class enables a PuppetDB server with defaults set for SIMP
# compatibility.
#
# **NOTE:** Hiera variables **must** be set appropriately under the puppetdb
# namespace
#
# @param trusted_nets
#   This is used to allow specific hosts access to PuppetDB
#
#   * This should be restricted to only those hosts that need to talk to
#     PuppetDB, primarly Puppet Masters.
#
#   * Unfortunately, this cannot be set via exported resources since PuppetDB
#     needs to be running prior to exported resources functioning properly.
#     Once PuppetDB is up, then you can switch this to exported resources mode
#     using the **use_exported_resources** variable.
#
# All other parameters are taken directly from ``puppetdb::server``
#
# @param listen_address
# @param listen_port
# @param open_listen_port
# @param ssl_deploy_certs
# @param ssl_set_cert_paths
# @param ssl_listen_address
# @param ssl_listen_port
# @param use_puppet_ssl_certs
# @param disable_ssl
# @param manage_package_repo
# @param database_password
# @param read_database_username
# @param read_database_password
# @param read_database_name
# @param read_database_ssl
# @param manage_firewall
# @param manage_puppetserver
# @param java_max_memory
# @param java_start_memory
# @param java_tmpdir
# @param java_heapdump_on_oom
# @param java_prefer_ipv4
# @param firewall
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::puppetdb (
  Simplib::Netlist     $trusted_nets           = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
  Simplib::IP          $listen_address         = '127.0.0.1',
  Simplib::Port        $listen_port            = 8138,
  Boolean              $open_listen_port       = false,
  Boolean              $ssl_deploy_certs       = true,
  Boolean              $ssl_set_cert_paths     = true,
  Simplib::IP          $ssl_listen_address     = '0.0.0.0',
  Simplib::Port        $ssl_listen_port        = 8139,
  Boolean              $use_puppet_ssl_certs   = true,
  Boolean              $disable_ssl            = false,
  Boolean              $manage_package_repo    = false,
  String               $database_password      = simplib::passgen('simp_puppetdb'),
  String               $read_database_username = 'simp_puppetdb',
  String               $read_database_password = simplib::passgen('simp_read_puppetdb'),
  String               $read_database_name     = 'simp_puppetdb',
  Boolean              $read_database_ssl      = true,
  Boolean              $manage_firewall        = true,
  Boolean              $manage_puppetserver    = true,
  String               $java_max_memory        = '40%',
  Optional[String]     $java_start_memory      = undef,
  Stdlib::Absolutepath $java_tmpdir            = '/opt/puppetlabs/puppet/cache/pdb_tmp',
  Boolean              $java_heapdump_on_oom   = false,
  Boolean              $java_prefer_ipv4       = true,
  Boolean              $firewall               = simplib::lookup('simp_options::firewall', { 'default_value' => false })
) {

  simplib::assert_metadata( $module_name )

  $_simp_manage_firewall = ($manage_firewall and $firewall)

  $_java_max_memory = inline_template('<% if @java_max_memory[-1].chr == "%" %><%= (@memorysize_mb.to_f * (@java_max_memory[0..-2].to_f/100.0)).round.to_s + "m" %><% else %><%= @java_max_memory %><% end %>')

  if !defined('::puppetdb::java_args') or empty($::puppetdb::java_args) {
    $_java_heapdump_on_oom = $java_heapdump_on_oom ? {
      true    => '-XX:HeapDumpOnOutOfMemoryError',
      default => '-XX:-HeapDumpOnOutOfMemoryError'
    }

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

  if defined(Class['puppetdb::master::puppetdb_conf']) {
    # When puppetdb::master::config::manage_config is true (the default),
    # puppetdb.conf is managed using the inifile module, which creates
    # the file if it doesn't exist without explicitly setting ownership
    # and permissions.  To ensure the file is usable, no matter what the
    # umask of is of the process creating it, set the ownership and
    # permissions here.
    #
    # This smells like an upstream issue, and other have agreed
    # https://tickets.puppetlabs.com/browse/MODULES-5391
    # If puppetlabs/puppetdb gets updated, watch out for duplicate
    # declaration errors for this file resource.
    file { "${::puppetdb::master::puppetdb_conf::puppet_confdir}/puppetdb.conf":
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644'
    }
  }

  file { $java_tmpdir:
    ensure => 'directory',
    owner  => 'puppetdb',
    group  => 'puppetdb',
    mode   => '0640',
    before => Service[$::puppetdb::puppetdb_service]
  }

  if $manage_puppetserver and defined(Class['puppetdb::master::puppetdb_conf']) {
    # We will need to restart the puppet master service if certain config
    # files are changed, so here we make sure it's in the catalog.
    include 'pupmod::master::base'
    Class['puppetdb::master::puppetdb_conf'] ~> Class['pupmod::master::base']
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

    iptables::listen::tcp_stateful { 'puppetdb':
      dports       => [$::puppetdb::ssl_listen_port],
      trusted_nets => $trusted_nets,
      # Need this for the auto-connect test script
      before       => Service[$::puppetdb::puppetdb_service]
    }
  }
}
