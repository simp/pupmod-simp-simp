# This class sets up a YUM site at ${data_dir}/yum and is used by
# the default SIMP server.
#
# @param data_dir
#
# @param trusted_nets
#   The networks to allow into the YUM server.
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::yum_server (
  Stdlib::Absolutepath $data_dir     = '/var/www',
  Array[String]        $trusted_nets = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1','::1'] }),
){
  $l_trusted_nets = nets2cidr($trusted_nets)

  simp_apache::add_site { 'yum':
    content => template('simp/etc/httpd/conf.d/yum.conf.erb')
  }

  if $data_dir != '/var/www' {
    file { '/var/www/yum':
      ensure => 'link',
      target => "${data_dir}/yum"
    }

    file { $data_dir:
      ensure => 'directory',
      owner  => 'root',
      group  => 'apache',
      mode   => '0750'
    }
  }

  package { 'createrepo': ensure => 'latest' }
}
