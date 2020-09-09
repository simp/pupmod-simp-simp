# @summary Mount ``/proc``
#
# @param proc_hidepid
#   * 0: This is the system default setting and provides no access restrictions
#        on /proc
#
#   * 1: With this option an normal user would not see other processes but
#        their own about ``ps``, ``top`` , etc..., but they are still able to
#        see process IDs in ``/proc``
#
#   * 2 (default): Users are only able to see their own processes (like with
#       ``hidepid=1``), and process IDs are also hidden in ``/proc``!
#
# @param manage_proc_group
#   Enable management of the group that allows access to ``/proc``
#
#   * This was added, and enabled by default, to fix issue with updates to
#   ``polkit`` per the vendor recommended guidance
#
# @param proc_group
#   The group name to be associated with ``$proc_gid``
#
# @param proc_gid
#   This group will be able to see all processes on the system regardless of
#   the ``$proc_hidepid`` setting
#
#   * If this is set to ``0`` then the ``gid`` option will be removed from the
#     option string
#
class simp::mountpoints::proc (
  Integer[0,2]      $proc_hidepid      = 2,
  Boolean           $manage_proc_group = true,
  String[1]         $proc_group        = pick($facts.dig('simplib__mountpoints', '/proc', 'options_hash', '_gid__group'), 'simp_proc_read'),
  Integer[0]        $proc_gid          = pick($facts.dig('simplib__mountpoints', '/proc', 'options_hash', 'gid'), 231)
) {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  if $proc_gid == 0 {
    $_proc_options = "hidepid=${proc_hidepid}"
  }
  else {
    $_proc_options = "hidepid=${proc_hidepid},gid=${proc_gid}"
  }

  if ( $proc_gid > 0 ) and $manage_proc_group {
    group { $proc_group:
      ensure     => 'present',
      allowdupe  => false,
      forcelocal => true,
      gid        => $proc_gid,
      notify     => Mount['/proc']
    }
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
