# Manage the netconsole kernel parameter
#
# @see https://www.kernel.org/doc/Documentation/networking/netconsole.txt
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
# @param extended_console
#   Extended console support
#
# @param source_device
#   Network interface to broadcast logs from
#
# @param source_ip
#   IP address to send from
#
# @param source_port
#   Port of the send logs from
#
# @param target_port
#   UDP syslog receiver port
#
class simp::netconsole (
  Enum['present','absent'] $ensure,
  Simplib::IP      $target_ip,
  Optional[String] $target_macaddr   = undef,
  Boolean          $extended_console = false,
  String           $source_device    = $facts['networking']['interfaces'].keys[0],
  Variant[Enum[''],Simplib::IP]   $source_ip   = $facts['networking']['interfaces'][$source_device]['ip'],
  Variant[Enum[''],Simplib::Port] $source_port = 6665,
  Variant[Enum[''],Simplib::Port] $target_port = 6666,
) {

  $_extended       = $extended_console ? { true   => '+',                 default => '' }
  $_target_macaddr = $target_macaddr   ? { String => $target_macaddr,     default => '' }
  $_source_port    = $source_port      ? { Simplib::Port => $source_port, default => '' }
  $_target_port    = $target_port      ? { Simplib::Port => $target_port, default => '' }

  $_source = "${_source_port}@${source_ip}/${source_device}"
  $_dest   = "${_target_port}@${target_ip}/${_target_macaddr}"

  $_netconsole = "${_extended}${_source},${_dest}"


  kernel_parameter { 'netconsole':
    ensure => $ensure,
    value  => $_netconsole
  }
}
