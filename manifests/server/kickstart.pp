# This class provides a working framework for providing a kickstart
# server for your client hosts.
#
# Note, you need both a DHCP and TFTP server for unattended Kickstart
# to work but you can use your own if you already have them.
#
# @param data_dir
#
# @param trusted_nets
#   The networks to allow into the Kickstart server.
#
# @param manage_dhcp
#   If true, have this node act as a DHCP server.
#
# @param manage_tftpboot
#   If true, have this node act as a TFTP server.
#
# @param ntp_servers
#   An array of ntp servers or hash of server/vaule pairs that should
#   be used during client kickstarts to slew the local time correctly
#   prior to PKI key distribution.
#
#   Failure to set the system clock will not cause the runpuppet script to fail
#   to execute.
#
# @param puppet_server
#   The FQDN of your Puppet server
#
#   * If not set, will use ``$server_facts['servername']``
#
# @param puppet_ca
#   The FQDN of your Puppet CA
#
#   * If not set, will use ``$server_facts['servername']``
#
# @param puppet_ca_port
#   The port upon which the Puppet CA is listening.
#
# @param runpuppet_print_stats
#   If true, print statistics for each client puppet run during bootstrap.
#
# @param runpuppet_wait_for_cert
#   If set to an integer, the runpuppet client script will wait for this many
#   seconds between checking into the puppet master for a signed certificate.
#   This will go on until a signed certificate is presented.
#
#   If set to '' or 0, the client will immediately timeout if a signed
#   certificate is not presented.
#
# @param fips
#   If true, set puppet keylength to 2048, else 4096.
#
# @param sslverifyclient
#   Verify the certificate of the kickstart client.  One of optional, require,
#   none, optional_no_ca.
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::server::kickstart (
  Stdlib::Absolutepath        $data_dir                = '/var/www',
  Simplib::Netlist            $trusted_nets            = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1','::1'] }),
  Boolean                     $manage_dhcp             = true,
  Boolean                     $manage_tftpboot         = true,
  Variant[Array, Hash]        $ntp_servers             = simplib::lookup('simp_options::ntpd::servers', { 'default_value' => [] }),
  Optional[Simplib::Host]     $puppet_server           = simplib::lookup('simp_options::puppet::server', { 'default_value' => undef }),
  Optional[Simplib::Host]     $puppet_ca               = simplib::lookup('simp_options::puppet::ca', { 'default_value' => undef }),
  Simplib::Port               $puppet_ca_port          = simplib::lookup('simp_options::puppet::ca_port', { 'default_value' => 8141 }),
  Boolean                     $runpuppet_print_stats   = true,
  Variant[Integer[0],Boolean] $runpuppet_wait_for_cert = 10,
  Boolean                     $fips                    = simplib::lookup('simp_options::fips', { 'default_value' => false }),
  Enum['require','none']      $sslverifyclient         = 'none'
){
  if $manage_dhcp     { include '::dhcp::dhcpd' }
  if $manage_tftpboot { include '::tftpboot' }

  $_trusted_nets = nets2cidr($trusted_nets)

  include '::simp_apache'
  simp_apache::site { 'ks':
    content => template("${module_name}/etc/httpd/conf.d/ks.conf.erb")
  }

  if $puppet_server {
    $_puppet_server = $puppet_server
  }
  else {
    $_puppet_server = $server_facts['servername']
  }

  if $puppet_ca {
    $_puppet_ca = $puppet_ca
  }
  else {
    $_puppet_ca = $server_facts['servername']
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
