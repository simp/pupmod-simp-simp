# Set up a YUM update schedule.
#
# @param minute String Cron minute
# @param hour String Cron hour
# @param monthday String Cron monthday
# @param month String Cron month
# @param weekday String Cron weekday
#
# @param repos Array[String]
#     If you only want to update from specific repos, then set the repos
#     variable to an array with those repo names.
# @param disable Array[String]
#     If you want to disable specific repos, then set the $disable
#     variable to an array with those repo names.
# @param exclude_pkgs Array[String]
#     Packages to exclude from the update.
# @param randomize Integer
#     Set to the number of minutes you want yum to randomly wait within before
#     running.  The default is '5'.
# @param quiet Boolean
#     Set to false if you want to see the chatter from yum.
#
class simp::yum_schedule (
    $minute   = '12',
    $hour     = '0',
    $monthday = '*',
    $month    = '*',
    $weekday  = '*',
    $repos    = ['all'],
    $disable = [],
    $exclude_pkgs = [],
    $randomize = 5,
    Boolean $quiet = true
) {
  cron { 'yum_update':
    command  => template('simplib/yum-cron.erb'),
    user     => 'root',
    minute   => $minute,
    hour     => $hour,
    monthday => $monthday,
    month    => $month,
    weekday  => $weekday
  }
}
