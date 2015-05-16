# == Class: simp::base_apps
#
# This is a set of applications that you will want on most systems.
#
# == Parameters
# [*ensure*]
# Type: latest|present|absent
# Default: latest
#   The $ensure status of all of the included packages. Version
#   pinning is not supported. If you need that, do not include this
#   class.
#
# == Authors
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::base_apps (
#   What level to ensure for all base apps. Valid values are: 'latest',
#   'absent', or 'present'
  $ensure = 'latest'
) {
  package { 'bc':           ensure => $ensure }
  package { 'bind-utils':   ensure => $ensure }
  package { 'bridge-utils': ensure => $ensure }
  package { 'dos2unix':     ensure => $ensure }
  package { 'elinks':       ensure => $ensure }
  package { 'genisoimage':  ensure => $ensure }
  package { 'iptstate':     ensure => $ensure }
  package { 'lftp':         ensure => $ensure }
  package { 'lsof':         ensure => $ensure }
  package { 'man-pages':    ensure => $ensure }
  package { 'mlocate':      ensure => $ensure }
  package { 'pax':          ensure => $ensure }
  package { 'pinfo':        ensure => $ensure }
  package { 'screen':       ensure => $ensure }
  package { 'sos':          ensure => $ensure }
  package { 'star':         ensure => $ensure }
  package { 'symlinks':     ensure => $ensure }
  package { 'telnet':       ensure => $ensure }
  package { 'vim-enhanced': ensure => $ensure }
  package { 'words':        ensure => $ensure }
  package { 'x86info':      ensure => $ensure }

  file { '/etc/elinks.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['elinks']
  }

  file_line { 'elinks_ui_lang':
    path => '/etc/elinks.conf',
    line => 'set ui.language = "System"'
  }

  file_line { 'elinks_css_disable':
    path => '/etc/elinks.conf',
    line => 'set document.css.enable = 0'
  }

  case $::operatingsystem {
    'RedHat','CentOS': {
      if $::lsbmajdistrelease > '6' {
        package { 'hunspell':       ensure => $ensure }
      }
      else {
        package { 'aspell':       ensure => $ensure }
        package { 'lslk':         ensure => $ensure }
        package { 'man':          ensure => $ensure }
      }
    }
    default: {
      fail("${::operatingsystem} is not yet supported by ${module_name}")
    }
  }

  validate_array_member($ensure,['latest','present','absent'])
}
