# Build a list of GPG keys needed by a simp repo
#
# @return [Array<String>]
#
function simp::yum::repo::gpgkeys::simp() {
  if $facts['os']['family'] != 'RedHat' or ($facts['os']['name'] in ['Fedora','Amazon']) {
    fail("There are no Yumrepo GPG keys for OS '${facts['os']['name']}'")
  }

  [
    # Common keys, distributed in simp-gpgkeys
    'RPM-GPG-KEY-puppet-20250406',
    'RPM-GPG-KEY-puppet',
    'RPM-GPG-KEY-puppetlabs',
    'RPM-GPG-KEY-SIMP-6',
    'RPM-GPG-KEY-PGDG-94',
    # keys needed by specific OSes
    "RPM-GPG-KEY-EPEL-${facts['os']['release']['major']}",
  ] + simp::yum::repo::gpgkeys::os_updates()
}
