# == Class: simp::nfs::params ==
#
# == Parameters ==
#
# [*port*]
#   The target port on the LDAP server.  If none specified,
#   defaults to 389 for non-TLS/start_tls connections, and
#   636 for SSL connections.
#
# [*tls*]
#   Whether or not to enable SSL/TLS for the connection.
#   $tls = 'ssl'         -> LDAPS on port 636, unless  different *port* specified.
#                           Uses simple_tls; No validation of the LDAP server's SSL
#                           certificate is performed.
#   $tls = 'start_tls'   -> Start TLS on port 389, unless different *port* specified.
#   $tls = 'none'        -> LDAP on port 389, unless different *port* specified.
#                           No Encryption.
#
class simp::nfs::params {
  $tls  = 'start_tls'
  $port = $tls ? {
    'ssl' => '636',
    default => '389'
  }

  validate_port($port)
  validate_array_member($tls, ['ssl','start_tls','none'])
}
