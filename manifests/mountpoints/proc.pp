# This class mount /proc
#
# @params proc_hidepid
#   0: This is the default setting and gives you the default
#   behaviour.
#
#   1: With this option an normal user would not see other processes
#   but their own about ps, top etc, but he is still able to see
#   process IDs in /proc
#
#   2 (default): Users are only able too see their own processes (like
#   with hidepid=1), but also the other process IDs are hidden for
#   them in /proc!
#
#   This option has no effect if ``$manage_proc`` is not ``true``
#
# @params proc_gid
#   If set, this group will be able to see all processes on the system
#   regardless of the ``$proc_hidepid`` setting.
#
class simp::mountpoints::proc (
  Optional[Integer] $proc_gid     = undef,
  Integer[0,2]      $proc_hidepid = 2,
) {

  if $proc_gid {
    $_proc_options = "hidepid=${proc_hidepid},gid=${proc_gid}"
  }
  else {
    $_proc_options = "hidepid=${proc_hidepid}"
  }
  mount { '/proc':
    ensure   => 'mounted',
    atboot   => true,
    device   => 'proc',
    fstype   => 'proc',
    remounts => true,
    options  => $_proc_options
  }

}
