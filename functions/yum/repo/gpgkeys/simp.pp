# Build a list of GPG keys needed by a simp repo
function simp::yum::repo::gpgkeys::simp() >> Array[String] {

  # Common keys, distributed in simp-gpgkeys
  $_simp_gpgkeys = [
    'RPM-GPG-KEY-puppet',
    'RPM-GPG-KEY-puppetlabs',
    'RPM-GPG-KEY-SIMP',
    'RPM-GPG-KEY-elasticsearch',
    'RPM-GPG-KEY-grafana-legacy',
    'RPM-GPG-KEY-grafana',
    'RPM-GPG-KEY-PGDG-94'
  ]

  # keys needed by specific OSes
  if $facts['os']['name'] in ['RedHat','CentOS'] {
    case $facts['os']['release']['major'] {
      '6':     { $_os_rel_gpgkeys = ['RPM-GPG-KEY-EPEL-6'] }
      '7':     { $_os_rel_gpgkeys = ['RPM-GPG-KEY-EPEL-7'] }
      default: { $_os_rel_gpgkeys = [] }
    }
    $_full_os_gpgkeys = ($facts['os']['name'] == 'RedHat') ? {
      true    => concat( $_os_rel_gpgkeys, 'RPM-GPG-KEY-redhat-release' ),
      default =>  $_os_rel_gpgkeys
    }
  }
  else { fail("There are no Yumrepo GPG keys for OS '${facts['os']['name']}'") }

  concat( $_simp_gpgkeys, $_full_os_gpgkeys )
}
