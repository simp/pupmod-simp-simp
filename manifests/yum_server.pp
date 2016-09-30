# == Class: simp::yum_server
#
# This class sets up a YUM site at ${data_dir}/yum and is used by
# the default SIMP server.
#
# == Parameters
#
# [*data_dir*]
#   Type: Absolute Path
#   Default: versioncmp(simp_version(),'5') ? { '-1' => '/srv/www', default => '/var/www' }
#
# [*client_nets*]
# Type: Net List
# Default: hiera('client_nets')
#   The networks to allow into the YUM server.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::yum_server (
  $data_dir = versioncmp(simp_version(),'5') ? { '-1' => '/srv/www', default => '/var/www' },
  $client_nets = defined('$::client_nets') ? { true  => $::client_nets, default =>  hiera('client_nets') }
){
  $l_client_nets = nets2cidr($client_nets)

  simp_apache::add_site { 'yum':
    content => template('simp/etc/httpd/conf.d/yum.conf.erb')
  }

  if $data_dir != '/var/www' {
    file { '/var/www/yum':
      ensure => 'link',
      target => "${data_dir}/yum"
    }

    file { '/srv/www/yum/SIMP':
      ensure => 'directory',
      owner  => 'root',
      group  => 'apache',
      mode   => '0750'
    }
  }

  package { 'createrepo': ensure => 'latest' }
}
