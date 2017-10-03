# Places SIMP version related information on the filesystem
class simp::version {

  simplib::assert_metadata( $module_name )

  file { '/etc/simp':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
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
