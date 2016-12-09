# Populate /etc/ftpusers
#
# @params min_uid
#   The start of the local user account IDs. This is used to populate
#   /etc/ftpusers with all system accounts (below this number) so that
#   they cannot ftp into the system.
#
#   Set to an empty string ('') to disable.
#
class simp::ftpusers (
  Stdlib::Compat::Integer $min_uid = '500'
){
  if !empty($min_uid) {
    file { '/etc/ftpusers':
      ensure => 'file',
      force  => true,
      owner  => 'root',
      group  => 'root',
      mode   => '0600',
    }
    ftpusers { '/etc/ftpusers':
      min_id => $min_uid
    }
  }
}
