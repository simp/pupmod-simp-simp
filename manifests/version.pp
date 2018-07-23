# Places SIMP version related information on the filesystem
class simp::version () {
  # XXX: ToDo: Move /etc/simp creation to a simplib class and use
  # moduledata to resolve the variables..
  #
  # It's needed in more places then here, and they don't need to pull in
  # anything else from simp
  if (downcase($facts['kernel']) == 'windows') {
    $simp_root_dir = 'C:/ProgramData/SIMP'
    $simp_root_dir_user = 'BUILTIN\Administrators'
    $simp_root_dir_group = 'BUILTIN\Administrators'
    # Windows permission model is different then *nix,
    # so 770 is the only one that can be translated without
    # also pulling in windows_acl
    $simp_root_dir_mode = '0770'
  } else {
    $simp_root_dir = '/etc/simp'
    $simp_root_dir_group = 'root'
    $simp_root_dir_user = 'root'
    $simp_root_dir_mode = '0640'
    file { '/usr/local/sbin/simp':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0640'
    }
  }
  ensure_resource('file', $simp_root_dir, {
    ensure => 'directory',
    owner  => $simp_root_dir_user,
    group  => $simp_root_dir_group,
    mode   => $simp_root_dir_mode
  })

  file { "${simp_root_dir}/simp.version":
    ensure  => 'file',
    owner   => $simp_root_dir_user,
    group   => $simp_root_dir_group,
    mode    => $simp_root_dir_mode,
    content => simp_version()
  }
}
