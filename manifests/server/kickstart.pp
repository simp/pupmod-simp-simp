# @summary This class provides a working framework for providing a kickstart
# server for your client hosts.
#
# @note You need both a DHCP and TFTP server for unattended Kickstart
#       to work but you can use your own if you already have them.
#
# @note This module uses the legacy simp_apache module to provide
#       web-hosting, and as such **requires** the use of Hiera or
#       another APL source to properly configure the web server.
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
#   Deprecated  The runpuppet script has been replaced by the
#   simp_client_bootstrap script.  The runpuppet script did
#   not work well on CentOS 7 and will not work on CentOS 8.
#   Remember to update your kickstart scripts to call the correct
#   script. See the bootstrap scripts in simp-core under build/distributions
#   for examples.
#   This parameter will be removed in later versions.
#
# @param manage_simp_client_bootstrap
#   If true, generate the simp_client_bootstrap sysv init
#   script and simp_client_bootstrap.service systemd
#   service unit file in $data_dir/ks.
#
# @param sslverifyclient
#   Verify the certificate of the kickstart client.  One of optional, require,
#   none, optional_no_ca.
#
# @author https://github.com/simp/pupmod-simp-simp/graphs/contributors
#
class simp::server::kickstart (
  Simplib::Netlist       $trusted_nets                 = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1','::1'] }),
  Stdlib::Absolutepath   $data_dir                     = '/var/www',
  Boolean                $manage_dhcp                  = true,
  Boolean                $manage_tftpboot              = true,
  Boolean                $manage_runpuppet             = false,
  Boolean                $manage_simp_client_bootstrap = true,
  Enum['require','none'] $sslverifyclient              = 'none'
) {
  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if $manage_dhcp      { include 'dhcp::dhcpd' }
  if $manage_tftpboot  { include 'tftpboot' }
  if $manage_runpuppet {
    deprecation('simp::server::manage_runpuppet','simp::server::manage_runpuppet has been deprecated.  Use simp::server::manage_simp_client_bootstrap instead')
  }

  if $manage_simp_client_bootstrap {
    contain 'simp::server::kickstart::simp_client_bootstrap'
  }

  $_trusted_nets = simplib::nets2cidr($trusted_nets)

  include 'simp_apache'
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
