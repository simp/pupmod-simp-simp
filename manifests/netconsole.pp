# Configure ``/etc/sysconfig/netconsole`` and the netconsole service
#
# @see https://www.kernel.org/doc/Documentation/networking/netconsole.txt and
#   https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-configuring_netconsole
#
# @param ensure
#   Ensure 'present' or 'absent' on the kernel parameter
#
# @param target_ip
#   UDP syslog receiver IP address
#
# @param target_macaddr
#   UDP syslog receiver MAC address
#
# @param target_port
#   UDP syslog receiver port
#
# @param source_port
#   Port of the send logs from
#
# @param source_device
#   Network interface to broadcast logs from
#
class simp::netconsole (
  Enum['present','absent']      $ensure,
  Optional[Simplib::IP]         $target_ip      = undef,
  Optional[Simplib::Port]       $target_port    = undef,
  Optional[Simplib::MacAddress] $target_macaddr = undef,
  Optional[Simplib::Port]       $source_port    = undef,
  Optional[String]              $source_device  = undef,
) {

  file { '/etc/sysconfig/netconsole':
    ensure  => $ensure,
    content => epp('simp/etc/sysconfig/netconsole.epp',
      {
        'syslogaddr'    => $target_ip,
        'syslogport'    => $target_port,
        'syslogmacaddr' => $target_macaddr,
        'localport'     => $source_port,
        'dev'           => $source_device,
      }
    )
  }

  service { 'netconsole':
    ensure => $ensure ? { 'present' => running, 'absent' => stopped },
    enable => $ensure ? { 'present' => true,    'absent' => false }
  }
}
