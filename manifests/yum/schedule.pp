# Set up a YUM update schedule.
#
# @param enable
#   Enable or disable the update schedule
#
# @param minute String Cron minute
# @param hour String Cron hour
# @param monthday String Cron monthday
# @param month String Cron month
# @param weekday String Cron weekday
#
# @param repos
#     If you only want to update from specific repos, then set the repos
#     variable to an Array with those repo names
#
# @param disable
#     If you want to disable specific repos, then set the $disable
#     variable to an Array with those repo names
#
# @param exclude_pkgs
#     Packages to exclude from the update
#
# @param randomize
#     Set to the number of minutes you want yum to randomly wait within before
#     running
#
# @param quiet
#     Set to false if you want to see the chatter from yum
#
class simp::yum::schedule (
  Boolean                       $enable       = true,
  Variant[String,Array[String]] $minute       = '12',
  Variant[String,Array[String]] $hour         = '0',
  Variant[String,Array[String]] $monthday     = '*',
  Variant[String,Array[String]] $month        = '*',
  Variant[String,Array[String]] $weekday      = '*',
  Array[String]                 $repos        = ['all'],
  Array[String]                 $disable      = [],
  Array[String]                 $exclude_pkgs = [],
  Integer                       $randomize    = 5,
  Boolean                       $quiet        = true
) {

  simplib::assert_metadata( $module_name )

  $_ensure = $enable ? {
    true    => 'present',
    default => 'absent'
  }

  cron { 'simp_yum_update':
    ensure   => $_ensure,
    command  => template('simp/yum-cron.erb'),
    user     => 'root',
    minute   => $minute,
    hour     => $hour,
    monthday => $monthday,
    month    => $month,
    weekday  => $weekday
  }
}
