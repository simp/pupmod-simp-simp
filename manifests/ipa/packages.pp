# Class to contain packages required for simp::ipa::install
#
class simp::ipa::packages {
  assert_private()

  package { 'ipa-client':
    ensure => $simp::ipa::install::ipa_client_ensure,
  }

  if $facts['os']['release']['major'] < '7' {
    package { 'ipa-admintools':
      ensure => $simp::ipa::install::admin_tools_ensure,
    }
  }
}
