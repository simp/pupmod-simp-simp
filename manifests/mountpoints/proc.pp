# Mount ``/proc``
#
# @param proc_hidepid
#   * 0: This is the default setting and gives you the default
#        behavior
#
#   * 1: With this option an normal user would not see other processes but
#        their own about ``ps``, ``top`` , etc..., but they are still able to
#        see process IDs in ``/proc``
#
#   * 2 (default): Users are only able to see their own processes (like with
#       ``hidepid=1``), and process IDs are also hidden in ``/proc``!
#
#   * **NOTE:** This option has no effect if ``$manage_proc`` is not ``true``
#
# @param proc_gid
#   This group will be able to see all processes on the system regardless of
#   the ``$proc_hidepid`` setting
#
class simp::mountpoints::proc (
  Integer[0,2]      $proc_hidepid = 2,
  Optional[Integer] $proc_gid     = undef
) {

  simplib::assert_metadata( $module_name )

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
