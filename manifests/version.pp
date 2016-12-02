# Drops SIMP and SIMP-version related information to the filesystem.
#
class simp::version {
  file { '/etc/simp':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/etc/simp/simp.version':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => simp_version()
  }

  file { '/usr/local/sbin/simp':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0640'
  }
}
