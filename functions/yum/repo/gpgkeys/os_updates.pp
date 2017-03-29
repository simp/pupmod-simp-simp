# Build a list of GPG keys needed by a os_updates repo
function simp::yum::repo::gpgkeys::os_updates() >> Array[String] {
  $release_key = $facts['os']['name'] ? {
    'RedHat' => 'RPM-GPG-KEY-redhat-release',
    default  => "RPM-GPG-KEY-${facts['os']['name']}-${facts['os']['release']['major']}"
  }
  [$release_key]
}
