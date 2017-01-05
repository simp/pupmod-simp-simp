# Set up java, activemq, and mcollective with SSL fully enabled
#
# See the [MCollective README](modules/mcollective/README) for more information
#
# @param activemq_server_config
#   The content for activemq
#
# @param trusted_nets
#   The IP range on which the ``activemq_port`` variable will be open
#
# @param activemq_port
#   The port to open for activemq
#
# @param truststore_certificate
#   Path to the CA file to be placed in the activemq truststore
#
# @param truststore_target
#   Path to install the activemq truststore
#
# @param truststore_password
#   Password to access the activemq truststore
#
# @param keystore_certificate
#   Path to the cert to use for the activemq keystore
#
# @param keystore_key
#   Path to the key to use for the activemq keystore
#
# @param keystore_target
#   Path to install the activemq keystore
#
# @param keystore_password
#   Password to access the activemq keystore
#
# @param installplugins
#   Install the Puppet, Service and Package mcollective plugins
#
# @author Nick Markowski <nmarkowski@keywcorp.com>
#
class simp::mcollective (
  Boolean                          $mco_server              = true,
  Boolean                          $mco_client              = false,
  Simplib::Netlist                 $trusted_nets            = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
  Stdlib::Absolutepath             $truststore_certificate  = '/etc/pki/cacerts/cacerts.pem',
  Stdlib::Absolutepath             $truststore_target       = '/etc/activemq/truststore.jks',
  String                           $truststore_password     = passgen('simp_mco_truststore'),
  Stdlib::Absolutepath             $keystore_certificate    = "/etc/pki/public/${facts['fqdn']}.pub",
  Stdlib::Absolutepath             $keystore_key            = "/etc/pki/private/${facts['fqdn']}.pem",
  Stdlib::Absolutepath             $keystore_target         = '/etc/activemq/keystore.jks',
  String                           $keystore_password       = passgen('simp_mco_keystore'),
  Optional[String]                 $activemq_server_config  = undef,
  Boolean                          $activemq_ssl            = true,
  String                           $activemq_user           = passgen('simp_mco_activemq_username', { 'length' => 12, 'complexity' => 0 }),
  String                           $activemq_password       = passgen('simp_mco_activemq'),
  String                           $activemq_admin_user     = passgen('simp_mco_activemq_admin_username', { 'length' => 12, 'complexity' => 0}),
  String                           $activemq_admin_password = passgen('simp_mco_activemq_admin'),
  Optional[Simplib::Port]          $activemq_port           = undef,
  Boolean                          $activemq_console        = false,
  Pattern[/^([0-9]+\s)[kmgt][b]$/] $activemq_memory_usage   = '20 mb',
  Pattern[/^([0-9]+\s)[kmgt][b]$/] $activemq_store_usage    = '1 gb',
  Pattern[/^([0-9]+\s)[kmgt][b]$/] $activemq_temp_usage     = '100 mb',
  Simplib::Netlist                 $activemq_brokers        = [$facts['fqdn']],
  Boolean                          $installplugins          = true
) {
  if $activemq_port {
    $_activemq_port = $activemq_port
  }
  else {
    if $activemq_ssl {
      $_activemq_port = 61614
    }
    else {
      $_activemq_port = 61613
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

    iptables::listen::tcp_stateful { 'allow_activemq':
      trusted_nets => $trusted_nets,
      dports       => $_activemq_port
    }

    pam::access::rule { 'activemq':
      users   => ['activemq'],
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
