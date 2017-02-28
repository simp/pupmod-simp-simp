# This class provides a working framework for providing a kickstart
# server for your client hosts.
#
# Note, you need both a DHCP and TFTP server for unattended Kickstart
# to work but you can use your own if you already have them.
#
# @param data_dir
#   The location of the web root in which the kickstart directory,
#   'ks', will reside.
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
# @param manage_runpuppet
#   If true, generate the runpuppet script in $data_dir/ks.
#
# @param sslverifyclient
#   Verify the certificate of the kickstart client.  One of optional, require,
#   none, optional_no_ca.
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::server::kickstart (
  Simplib::Netlist       $trusted_nets            = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1','::1'] }),
  Stdlib::Absolutepath   $data_dir                = '/var/www',
  Boolean                $manage_dhcp             = true,
  Boolean                $manage_tftpboot         = true,
  Boolean                $manage_runpuppet        = true,
  Enum['require','none'] $sslverifyclient         = 'none'
) {
  if $manage_dhcp      { include '::dhcp::dhcpd' }
  if $manage_tftpboot  { include '::tftpboot' }
  if $manage_runpuppet {
    class { 'simp::server::kickstart::runpuppet':
      data_dir => $data_dir
    }
  }

  $_trusted_nets = nets2cidr($trusted_nets)

  include '::simp_apache'
  simp_apache::site { 'ks':
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

}
