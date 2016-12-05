# This class provides a default set of blacklist entries per the SCAP
# Security Guide.
#
# @param enable_defaults Boolean
#   Enable to use the default blacklist, otherwise just the custom_blacklist will be used.
#
# @param default_blacklist Array[String]
#   List of kernel modules to be included by default
#
# @param custom_blacklist Array[String]
#   Other kernel modules to be blacklisted
#
class simp::kmod_blacklist (
  Boolean $enable_defaults = true,
  Array[String] $default_blacklist = [
    'bluetooth',
    'cramfs',
    'dccp',
    'dccp_ipv4',
    'dccp_ipv6',
    'freevxfs',
    'hfs',
    'hfsplus',
    'ieee1394',
    'jffs2',
    'net-pf-31',
    'rds',
    'sctp',
    'squashfs',
    'tipc',
    'udf',
    'usb-storage'
  ],
  Array[String] $custom_blacklist = []
) {

  if $enable_defaults {
    $blacklist = $custom_blacklist + $default_blacklist
  }
  else {
    $blacklist = $custom_blacklist
  }

  $blacklist.each |String $mod| {
    kmod::blacklist { $mod: }
  }

}
