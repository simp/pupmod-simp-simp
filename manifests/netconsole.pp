# @summary Configure ``/etc/sysconfig/netconsole`` and the netconsole service
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
# @param package_ensure
#   The `ensure` parameter for the netconsole package when applicable
class simp::netconsole (
  Enum['present','absent']      $ensure,
  Optional[Simplib::IP]         $target_ip      = undef,
  Optional[Simplib::Port]       $target_port    = undef,
  Optional[Simplib::MacAddress] $target_macaddr = undef,
  Optional[Simplib::Port]       $source_port    = undef,
  Optional[String]              $source_device  = undef,
  String[1]                     $package_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })
) {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if (versioncmp($facts.dig('os','release','major'), '8') >= 0) {
    if ($ensure == 'present') {
      package { 'netconsole-service':
        ensure => $package_ensure,
        notify => [
          Service['netconsole'],
          File['/etc/sysconfig/netconsole']
        ]
      }
    }
    else {
      package { 'netconsole-service': ensure => $ensure }
    }
  }

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

  $_netconsole_ensure = $ensure ? { 'present' => running, 'absent' => stopped }
  $_netconsole_enable = $ensure ? { 'present' => true,    'absent' => false }
  service { 'netconsole':
    ensure => $_netconsole_ensure,
    enable => $_netconsole_enable
  }
}
