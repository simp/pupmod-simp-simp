# @summary Restrict the max logins on a system via PAM
#
# @param value
#   The maximum number of logins that a user may have simultaneously
#
#   * The default meets ``CCE-27457-1``
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::pam_limits::max_logins (
  Pam::Limits::Value $value = 10
) {

  simplib::module_metadata::assert($module_name, { 'blacklist' => ['Windows'] })

  pam::limits::rule { 'max_logins':
    domains => ['*'],
    type    => 'hard',
    item    => 'maxlogins',
    value   => $value,
    order   => 100
  }
}
