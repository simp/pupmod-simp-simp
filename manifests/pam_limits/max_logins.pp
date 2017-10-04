# Restrict the max logins on a system via PAM
#
# @param value
#   The maximum number of logins that a user may have simultaneously
#
#   * The default meets ``CCE-27457-1``
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::pam_limits::max_logins (
  Integer[0] $value = 10
) {

  simplib::assert_metadata( $module_name )

  pam::limits::rule { 'max_logins':
    domains => ['*'],
    type    => 'hard',
    item    => 'maxlogins',
    value   => $value,
    order   => 100
  }
}
