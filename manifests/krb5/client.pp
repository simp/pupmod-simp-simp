# == Class: simp::krb5::client
#
# A stock client class that will connect with the stock KDC
#
# == Parameters
#
# [*kdc*]
#   The default KDC for the $::domain realm.
#   Defaults to the puppet server.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::krb5::client (
  $kdc = hiera('puppet::server',$::servername),
  $kdc_realm = $::domain
) {

  include 'krb5'

  krb5::conf::realm { $kdc_realm:
    admin_server => $kdc,
    kdc          => $kdc
  }
}
