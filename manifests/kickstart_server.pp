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
#   The FQDN of your Puppet server.
#
# @param puppet_ca
#   The FQDN of your Puppet CA.
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
class simp::kickstart_server (
  Stdlib::Absolutepath    $data_dir                = '/var/www',
  Array[String]           $trusted_nets            = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1','::1'] }),
  Boolean                 $manage_dhcp             = true,
  Boolean                 $manage_tftpboot         = true,
  Variant[Array, Hash]    $ntp_servers             = simplib::lookup('simp_options::ntpd::servers', { 'default_value' => [] }),
  String                  $puppet_server           = simplib::lookup('simp_options::puppet::server', { 'default_value' => $::servername }),
  String                  $puppet_ca               = simplib::lookup('simp_options::puppet::ca', { 'default_value' => $::servername }),
  Stdlib::Compat::Integer $puppet_ca_port          = simplib::lookup('simp_options::puppet::ca_port', { 'default_value' => 8141 }),
  Boolean                 $runpuppet_print_stats   = true,
  Optional[Integer]       $runpuppet_wait_for_cert = 10,
  Boolean                 $fips                    = simplib::lookup('simp_options::fips', { 'default_value' => false }),
  String                  $sslverifyclient         = 'none'
){
  if $manage_dhcp     { include '::dhcp::dhcpd' }
  if $manage_tftpboot { include '::tftpboot' }

  validate_net_list($puppet_server)
  validate_net_list($puppet_ca)

  $l_trusted_nets = nets2cidr($trusted_nets)

  simp_apache::add_site { 'ks':
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
