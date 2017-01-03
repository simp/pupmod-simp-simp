# This class provides a default set of blacklist entries per the SCAP Security
# Guide
#
# @param enable_defaults
#   Enable to use the default blacklist, otherwise just the
#   ``$custom_blacklist`` will be used
#
# @param blacklist
#   List of kernel modules to be blacklisted by default
#
# @param custom_blacklist
#   Additional kernel modules to be blacklisted
#
class simp::kmod_blacklist (
  Boolean         $enable_defaults  = true,
  Array[String,1] $blacklist        = [
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
  Array[String]   $custom_blacklist = []
) {

  if $enable_defaults {
    $_blacklist = $custom_blacklist + $blacklist
  }
  else {
    $_blacklist = $custom_blacklist
  }

  $_blacklist.each |String $mod| { kmod::blacklist { $mod: } }
}
