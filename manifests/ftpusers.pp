# Populate /etc/ftpusers
#
# @params ftpusers_min String
#   The start of the local user account IDs. This is used to populate
#   /etc/ftpusers with all system accounts (below this number) so that
#   they cannot ftp into the system.
#
#   Set to an empty string ('') to disable.
class simp::ftpusers (
  String $ftpusers_min                = '500'

){
  if !empty($ftpusers_min) {
    file { '/etc/ftpusers':
      ensure => 'file',
      force  => true,
      owner  => 'root',
      group  => 'root',
      mode   => '0600'
    }
    ftpusers { '/etc/ftpusers': min_id => $ftpusers_min }
  }
}
