# == Class: Simp MCollective
#
# This class sets up java, activemq, and mcollective with SSL fully enabled.
#
# See the MCollective README for more information (modules/mcollective/README)
#
# == Parameters
#
# [*server_config*]
# Type: Template
# Default : template('simp/activemq.xml.erb')
#   The template to use for activemq.
#
# [*client_nets*]
# Type: Netlist in CIDR form
# Default : $::client_nets
#   The ip range on which the iptables_port variable will be open.
#
# [*iptables_port*]
# Type: String
# Default: 61614
#   The port to open for activemq.
#
# [*truststore_certificate*]
# Type: String
# Default: /etc/pki/cacerts/cacerts.pem
#   Path to the ca file to be placed in the activemq truststore.
#
# [*truststore_target*]
# Type: String
# Default: '/etc/activemq/truststore.jks'
#   Path to install the activemq truststore.
#
# [*truststore_password*]
# Type: String
# Default: No default
#   Password to access the activemq truststore.
#
# [*keystore_certificate*]
# Type: String
# Default: /etc/pki/public/${::fqdn}.pub
#   Path to the cert to use for the activemq keystore.
#
# [*keystore_key*]
# Type: String
# Default: /etc/pki/private/${::fqdn}.pem
#   Path to the key to use for the activemq keystore.
#
# [*keystore_target*]
# Type: String
# Default: /etc/activemq/keystore.jks
#   Path to install the activemq keystore.
#
# [*keystore_password*]
# Type: String
# Default: No default
#   Password to access the activemq keystore.
#
# [*installplugins*]
# Type: boolean
# Default: true
#   Install the Puppet, Service and Package mcollective plugins
#
# == Hiera Variables
#
# All hiera variables are used in both mcollective and activemq
# modules.  See the mcollective module README for further documentation.
#
# == Example Setup
#
# See the MCollective README for usage. (modules/mcollective/README)
#
# == Authors
#
# Nick Markowski <nmarkowski@keywcorp.com>
#
class simp::mcollective (
  $server_config = 'UNDEF',
  $client_nets = hiera('client_nets'),
  $iptables_port = '61614',
  $truststore_certificate = '/etc/pki/cacerts/cacerts.pem',
  $truststore_target = '/etc/activemq/truststore.jks',
  $truststore_password,
  $keystore_certificate = "/etc/pki/public/${::fqdn}.pub",
  $keystore_key = "/etc/pki/private/${::fqdn}.pem",
  $keystore_target = '/etc/activemq/keystore.jks',
  $keystore_password,
  $middleware_ssl = hiera(mcollective::middleware_ssl, true),
  $middleware_user = hiera(mcollective::middleware_user, 'mcollective'),
  $middleware_password = hiera(mcollective::middleware_password),
  $middleware_admin_user = hiera(mcollective::middleware_admin_user, 'admin'),
  $middleware_admin_password = hiera(mcollective::middleware_admin_password),
  $activemq_memoryUsage = hiera(mcollective::activemq_memoryUsage, '20 mb'),
  $activemq_storeUsage = hiera(mcollective::activemq_storeUsage, '1 gb'),
  $activemq_tempUsage = hiera(mcollective::activemq_tempUsage, '100 mb'),
  $installplugins = true
) {
  include '::java'
  include '::mcollective'
  include '::activemq'

  if $server_config != 'UNDEF' {
    $l_server_config = $server_config
  }
  else {
    $l_server_config = template('simp/activemq.xml.erb')
  }

  file { '/etc/activemq/activemq.xml':
    ensure  => file,
    owner   => 'root',
    group   => 'activemq',
    mode    => '0640',
    content => $l_server_config,
    notify  => Class['activemq::service'],
    require => Class['activemq::packages']
  }

  iptables::add_tcp_stateful_listen { 'allow_activemq_nossl':
    client_nets => $client_nets,
    dports      => $iptables_port,
  }

  pam::access::manage { 'activemq':
    users   => 'activemq',
    origins => ['LOCAL'],
    notify  => Class['activemq::service']
  }


  java_ks { 'mcollective::truststore':
    ensure       => 'latest',
    certificate  => $truststore_certificate,
    target       => $truststore_target,
    password     => $truststore_password,
    trustcacerts => true,
    notify       => Class['activemq::service'],
    require      => Class['activemq::packages'],
  }

  file { 'truststore_target' :
    path    => $truststore_target,
    owner   => 'activemq',
    group   => 'activemq',
    mode    => '0400',
    require => Java_ks['mcollective::truststore'],
    before  => Java_ks['mcollective:keystore']
  }

  java_ks { 'mcollective:keystore' :
    ensure       => 'latest',
    certificate  => $keystore_certificate,
    private_key  => $keystore_key,
    target       => $keystore_target,
    password     => $keystore_password,
    trustcacerts => true,
    before       => Class['activemq::service'],
  }

  file { 'keystore_target' :
    path    => $keystore_target,
    owner   => 'activemq',
    group   => 'activemq',
    mode    => '0400',
    require => Java_ks['mcollective:keystore'],
    before  => Class['activemq::service']
  }

  #Install mcollective plugins by default
  if $installplugins {
    mcollective::plugin { 'puppet':
      package => true,
    }

    mcollective::plugin { 'service':
      package => true,
    }

    mcollective::plugin { 'package':
      package => true,
    }
  }

  validate_net_list($client_nets,'^(any|ALL)$')
  validate_port($iptables_port)
  validate_absolute_path($truststore_certificate)
  validate_absolute_path($truststore_target)
  validate_absolute_path($keystore_certificate)
  validate_absolute_path($keystore_key)
  validate_absolute_path($keystore_target)
  validate_bool($middleware_ssl)
  validate_string($middleware_user)
  validate_string($middleware_admin_user)
  validate_re($activemq_memoryUsage, '^([0-9]+\s)[kmgt][b]$')
  validate_re($activemq_storeUsage, '^([0-9]+\s)[kmgt][b]$')
  validate_re($activemq_tempUsage, '^([0-9]+\s)[kmgt][b]$')
  validate_bool($installplugins)
}
