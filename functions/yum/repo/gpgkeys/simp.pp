# Build a list of GPG keys needed by a simp repo
#
# @return [Array<String>]
#
function simp::yum::repo::gpgkeys::simp() {

  # Common keys, distributed in simp-gpgkeys
  $_simp_gpgkeys = [
    'RPM-GPG-KEY-puppet',
    'RPM-GPG-KEY-puppetlabs',
    'RPM-GPG-KEY-SIMP',
    'RPM-GPG-KEY-elasticsearch',
    'RPM-GPG-KEY-grafana-legacy',
    'RPM-GPG-KEY-grafana',
    'RPM-GPG-KEY-PGDG-94',
    'RPM-GPG-KEY-PGDG-96'
  ]

  # keys needed by specific OSes
  if $facts['os']['name'] in ['RedHat','CentOS','OracleLinux'] {
    case $facts['os']['release']['major'] {
      '6':     { $_os_rel_gpgkeys = ['RPM-GPG-KEY-EPEL-6'] }
      '7':     { $_os_rel_gpgkeys = ['RPM-GPG-KEY-EPEL-7'] }
      default: { $_os_rel_gpgkeys = [] }
    }

    $_full_os_gpgkeys = case $facts['os']['name'] {
      'RedHat':      { concat( $_os_rel_gpgkeys, 'RPM-GPG-KEY-redhat-release' ) }
      'OracleLinux': { concat( $_os_rel_gpgkeys, 'RPM-GPG-KEY-oracle' ) }
      default:       { $_os_rel_gpgkeys }
    }
  }
  else { fail("There are no Yumrepo GPG keys for OS '${facts['os']['name']}'") }

  concat( $_simp_gpgkeys, $_full_os_gpgkeys )
}
