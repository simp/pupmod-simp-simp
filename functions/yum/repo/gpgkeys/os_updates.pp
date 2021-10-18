# Build a list of GPG keys needed by a os_updates repo
#
# @return [Array<String>]
function simp::yum::repo::gpgkeys::os_updates() {
  case $facts['os']['name'] {
    'RedHat': {$release_key = 'RPM-GPG-KEY-redhat-release'}
    'OracleLinux': {$release_key = 'RPM-GPG-KEY-oracle'}
    'CentOS': {
      case $facts['os']['release']['major'] {
        '7','8': {  $release_key = "RPM-GPG-KEY-${facts['os']['name']}-${facts['os']['release']['major']}"}
        default: { $release_key = "RPM-GPG-KEY-${facts['os']['name']}-Official"}
      }
    }
    default: { $release_key = "RPM-GPG-KEY-${facts['os']['name']}" }
  }
  [$release_key]
}
