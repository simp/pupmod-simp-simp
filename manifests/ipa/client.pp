# Generic profile for IPA, similiar to simp::admin
#
# @param ipa_posix_group Group that should be allowed to log in
# @param pam Enable pam
# @param posix_allowed_from Networks that the group from above is allowed from
#
class simp::ipa::client (
  String           $ipa_posix_group    = 'posixusers',
  Boolean          $pam                = simplib::lookup('simp_options::pam', { 'default_value' => false }),
  Simplib::Netlist $posix_allowed_from = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
) {

  if $pam {
    pam::access::rule { "Allow ${ipa_posix_group}":
      comment => "Allow the ${ipa_posix_group} to access the system from anywhere",
      users   => ["(${ipa_posix_group})"],
      origins => $posix_allowed_from
    }
  }
}
