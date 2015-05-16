# == Class: simp::mrepo::apache
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::mrepo::apache (
  $client_nets = hiera('client_nets')
){
  include 'apache'

  apache::add_site { 'mrepo':
    content => template('mrepo/httpd.mrepo.conf.erb')
  }
}
