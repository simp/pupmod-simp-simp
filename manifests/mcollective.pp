# == Class: Simp MCollective
#
# This class sets up java, activemq, and mcollective with SSL fully enabled.
#
# See the MCollective README for more information (modules/mcollective/README)
#
# == Parameters
#
# [*activemq_server_config*]
# Type: Template
# Default : template('simp/activemq.xml.erb')
#   The template to use for activemq.
#
# [*client_nets*]
# Type: Netlist in CIDR form
# Default : $::client_nets
#   The ip range on which the activemq_port variable will be open.
#
# [*activemq_port*]
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
  Boolean                           $mco_server              = true,
  Boolean                           $mco_client              = false,
  Array[String]                     $client_nets             = defined('$::client_nets') ? { true => getvar('::client_nets'), default => hiera('client_nets', ['127.0.0.1']) },
  Stdlib::Absolutepath              $truststore_certificate  = '/etc/pki/cacerts/cacerts.pem',
  Stdlib::Absolutepath              $truststore_target       = '/etc/activemq/truststore.jks',
  String                            $truststore_password     = passgen('simp_mco_truststore'),
  Stdlib::Absolutepath              $keystore_certificate    = "/etc/pki/public/${::fqdn}.pub",
  Stdlib::Absolutepath              $keystore_key            = "/etc/pki/private/${::fqdn}.pem",
  Stdlib::Absolutepath              $keystore_target         = '/etc/activemq/keystore.jks',
  String                            $keystore_password       = passgen('simp_mco_keystore'),
  Optional[String]                  $activemq_server_config  = undef,
  Boolean                           $activemq_ssl            = true,
  String                            $activemq_user           = passgen('simp_mco_activemq_username', { 'length' => 12, 'complexity' => 0 }),
  String                            $activemq_password       = passgen('simp_mco_activemq'),
  String                            $activemq_admin_user     = passgen('simp_mco_activemq_admin_username', { 'length' => 12, 'complexity' => 0}),
  String                            $activemq_admin_password = passgen('simp_mco_activemq_admin'),
  String                            $activemq_port           = '',
  Boolean                           $activemq_console        = false,
  Pattern[/^([0-9]+\s)[kmgt][b]$/]  $activemq_memory_usage   = '20 mb',
  Pattern[/^([0-9]+\s)[kmgt][b]$/]  $activemq_store_usage    = '1 gb',
  Pattern[/^([0-9]+\s)[kmgt][b]$/]  $activemq_temp_usage     = '100 mb',
  Array[String]                     $activemq_brokers        = [$::fqdn],
  Boolean                           $installplugins          = true
) {

  validate_net_list($client_nets)

  if !empty($activemq_port) {
    validate_port($activemq_port)
    $_activemq_port = $activemq_port
  }
  else {
    if $activemq_ssl {
      $_activemq_port = '61614'
    }
    else {
      $_activemq_port = '61613'
    }
  }

  if $activemq_ssl {
    class { '::mcollective':
      server              => $mco_server,
      client              => $mco_client,
      version             => 'latest',
      middleware_hosts    => $activemq_brokers,
      middleware_user     => $activemq_user,
      middleware_password => $activemq_password,
      middleware_ssl_port => $_activemq_port,
      middleware_ssl      => true,
      middleware_ssl_ca   => $truststore_certificate,
      middleware_ssl_cert => $keystore_certificate,
      middleware_ssl_key  => $keystore_key,
      ssl_mco_autokeys    => true,
      securityprovider    => 'ssl',
      connector           => 'activemq'
    }
  }
  else {
    class { '::mcollective':
      server              => $mco_server,
      client              => $mco_client,
      version             => 'latest',
      middleware_hosts    => $activemq_brokers,
      middleware_user     => $activemq_user,
      middleware_password => $activemq_password,
      middleware_port     => $_activemq_port,
      middleware_ssl      => false,
      securityprovider    => 'ssl',
      connector           => 'activemq'
    }
  }

  #Install mcollective plugins by default
  if $installplugins {
    mcollective::plugin { 'puppet': package => true }
    mcollective::plugin { 'service': package => true }
    mcollective::plugin { 'package': package => true }
  }

  if $mco_server {
    include '::pki'
    include '::java'

    if $activemq_server_config {
      $_activemq_server_config = $activemq_server_config
    }
    else {
      $_activemq_server_config = template('simp/activemq.xml.erb')
    }

    class { '::activemq':
      version                 => 'latest',
      instance                => 'simp_mco',
      server_config           => $_activemq_server_config,
      server_config_show_diff => false,
      mq_admin_username       => $activemq_admin_user,
      mq_admin_password       => $activemq_admin_password,
      mq_cluster_username     => $activemq_user,
      mq_cluster_password     => $activemq_password,
      mq_cluster_brokers      => $activemq_brokers
    }

    iptables::add_tcp_stateful_listen { 'allow_activemq':
      client_nets => $client_nets,
      dports      => $_activemq_port
    }

    pam::access::manage { 'activemq':
      users   => 'activemq',
      origins => ['LOCAL'],
      notify  => Class['activemq::service']
    }

    java_ks { 'mcollective_truststore':
      ensure       => 'latest',
      certificate  => $truststore_certificate,
      target       => $truststore_target,
      password     => $truststore_password,
      trustcacerts => true,
      notify       => Class['activemq::service'],
      require      => Class['activemq::packages']
    }

    file { $truststore_target:
      owner   => 'activemq',
      group   => 'activemq',
      mode    => '0400',
      require => Java_ks['mcollective_truststore'],
      before  => Java_ks['mcollective_keystore']
    }

    java_ks { 'mcollective_keystore' :
      ensure       => 'latest',
      certificate  => $keystore_certificate,
      private_key  => $keystore_key,
      target       => $keystore_target,
      password     => $keystore_password,
      trustcacerts => true,
      require      => Class['pki'],
      before       => Class['activemq::service']
    }

    file { 'keystore_target' :
      path    => $keystore_target,
      owner   => 'activemq',
      group   => 'activemq',
      mode    => '0400',
      require => Java_ks['mcollective_keystore'],
      before  => Class['activemq::service']
    }
  }
}
