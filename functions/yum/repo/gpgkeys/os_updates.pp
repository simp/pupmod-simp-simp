# Build a list of GPG keys needed by a os_updates repo
#
# @return [Array<String>]
function simp::yum::repo::gpgkeys::os_updates() {
  $release_key = $facts['os']['name'] ? {
    'RedHat'      => 'RPM-GPG-KEY-redhat-release',
    'OracleLinux' => 'RPM-GPG-KEY-oracle',
    default       => "RPM-GPG-KEY-${facts['os']['name']}-${facts['os']['release']['major']}"
  }
  [$release_key]
}
