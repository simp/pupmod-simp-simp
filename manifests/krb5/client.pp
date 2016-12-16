# A stock client class that will connect with the stock KDC
#
# @param kdc
#   The default KDC for the $::domain realm.
#   Defaults to the puppet server.
#
# @param kdc_realm
#   Kerberos Realm
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::krb5::client (
  String $kdc       = hiera('puppet::server',$::servername),
  String $kdc_realm = $facts['domain']
) {

  include '::krb5'

  krb5::conf::realm { $kdc_realm:
    admin_server => $kdc,
    kdc          => $kdc
  }
}
