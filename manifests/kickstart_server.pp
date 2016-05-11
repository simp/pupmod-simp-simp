# == Class: simp::kickstart_server
#
# This class provides a working framework for providing a kickstart
# server for your client hosts.
#
# Note, you need both a DHCP and TFTP server for unattended Kickstart
# to work but you can use your own if you already have them.
#
# == Parameters
#
# [*data_dir*]
#   Type: Absolute Path
#   Default: versioncmp(simp_version(),'5') ? { '-1' => '/srv/www', default => '/var/www' }
#
# [*client_nets*]
# Type: Net List
# Default: hiera('client_nets')
#   The networks to allow into the Kickstart server.
#
# [*manage_dhcp*]
# Type: Boolean
# Default: true
#   If true, have this node act as a DHCP server.
#
# [*manage_tftpboot*]
# Type: Boolean
# Default: true
#   If true, have this node act as a TFTP server.
#
# [*ntp_servers*]
# Type: Hash or Array
# Default: hiera('ntpd::servers',[])
#   An array of ntp servers or hash of server/vaule pairs that should
#   be used during client kickstarts to slew the local time correctly
#   prior to PKI key distribution.
#
#   Failure to set the system clock will not cause the runpuppet script to fail
#   to execute.
#
# [*puppet_server*]
# Type: Hostname
# Default: hiera('puppet::server',"puppet.${::domain}")
#   The FQDN of your Puppet server.
#
# [*puppet_ca*]
# Type: Hostname
# Default: hiera('puppet::ca',"puppet.${::domain}")
#   The FQDN of your Puppet CA.
#
# [*puppet_ca_port*]
# Type: Port Number
# Default: hiera('puppet::ca_port','8141')
#   The port upon which the Puppet CA is listening.
#
# [*runpuppet_print_stats*]
# Type: Boolean
# Default: true
#   If true, print statistics for each client puppet run during bootstrap.
#
# [*runpuppet_wait_for_cert*]
# Type: Integer
# Default: '10'
#   If set to an integer, the runpuppet client script will wait for this many
#   seconds between checking into the puppet master for a signed certificate.
#   This will go on until a signed certificate is presented.
#
#   If set to '' or 0, the client will immediately timeout if a signed
#   certificate is not presented.
#
# [*use_fips*]
# Type: Boolean
# Default: defined('$::fips_enabled') ? { true => str2bool($::fips_enabled), default => hiera('use_fips', false) }
#   If true, set puppet keylength to 2048, else 4096.
#
# [*sslverifyclient*]
# Type: String
# Default: none
#   Verify the certificate of the kickstart client.  One of optional, require,
#   none, optional_no_ca.
#
# == Authors
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::kickstart_server (
  $data_dir = versioncmp(simp_version(),'5') ? { '-1' => '/srv/www', default => '/var/www' },
  $client_nets = defined('$::client_nets') ? { true  => $::client_nets, default =>  hiera('client_nets') },
  $manage_dhcp = true,
  $manage_tftpboot = true,
  $ntp_servers = defined('$::ntpd::servers') ? { true => $::ntpd::servers, default => hiera('ntpd::servers',[]) },
  $puppet_server = hiera('puppet::server',$::servername),
  $puppet_ca = hiera('puppet::ca',$::servername),
  $puppet_ca_port = hiera('puppet::ca_port',$::settings::ca_port),
  $runpuppet_print_stats = true,
  $runpuppet_wait_for_cert = '10',
  $use_fips = defined('$::fips_enabled') ? { true => str2bool($::fips_enabled), default => hiera('use_fips', false) },
  $sslverifyclient = 'none'
){
  if $manage_dhcp { include 'dhcp::dhcpd' }
  if $manage_tftpboot { include 'tftpboot' }

  validate_bool($use_fips)
  validate_bool($manage_dhcp)
  validate_bool($manage_tftpboot)
  if !is_array($ntp_servers) { validate_hash($ntp_servers) }
  else { validate_array($ntp_servers) }
  validate_net_list($puppet_server)
  validate_net_list($puppet_ca)
  validate_port($puppet_ca_port)
  validate_bool($runpuppet_print_stats)
  unless empty($runpuppet_wait_for_cert) { validate_integer($runpuppet_wait_for_cert) }
  validate_string($sslverifyclient)

  $l_client_nets = nets2cidr($client_nets)

  apache::add_site { 'ks':
    content => template("${module_name}/etc/httpd/conf.d/ks.conf.erb")
  }

  file { "${data_dir}/ks":
    ensure => 'directory',
    owner  => 'root',
    group  => 'apache',
    mode   => '2640'
  }

  if $data_dir != '/var/www' {
    file { '/var/www/ks':
      ensure => 'link',
      target => "${data_dir}/ks"
    }
  }

  file { "${data_dir}/ks/runpuppet":
    ensure  => 'present',
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    content => template("${module_name}/www/ks/runpuppet.erb")
  }
}
