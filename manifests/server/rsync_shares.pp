# Set up various rsync services that are needed by the SIMP clients
#
# If you don't have these provided somewhere, many of the modules will not
# function properly.
#
# If you want additional ``BIND DNS`` spaces to be served out from rsync,
# you'll need to enable them separately.
#
# @param rsync_base
#   The path to the beginning of the rsync space for this system. There must be
#   a directory per environment that you want to serve to clients.
#
#   * **NOTE** If you change this, you **MUST** create a custom fact for
#     ``simp_rsync_environments`` with a Fact ``weight`` higher than ``1``.
#
# @see https://docs.puppet.com/facter/latest/custom_facts.html Custom Fact Walkthrough
#
# @param use_stunnel If set, hosts_allow will be set to ``127.0.0.1`` so that
#   the stunnel'd rsync will be used.
#
# @param hosts_allow
#   The hosts from which to allow access to the rsync shares. This option has
#   no effect if ``$use_stunnel`` is ``true``.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::server::rsync_shares (
  String $rsync_base  = '/var/simp/rsync/environments',
  Boolean $use_stunnel = defined('$::use_stunnel') ? { true => $::use_stunnel, default => lookup('rsync::server::use_stunnel', { 'default_value' => true }) },
  Array[String] $hosts_allow = lookup('client_nets', Array, 'first', ['127.0.0.1']),
){

  validate_absolute_path($rsync_base)
  validate_bool($use_stunnel)
  validate_net_list($hosts_allow)

  include '::rsync::server::global'

  $_rsync_subdir = "${facts['operatingsystem']}/${facts['operatingsystemmajrelease']}"

  if $use_stunnel {
    $_hosts_allow = ['127.0.0.1']
  }
  else {
    $_hosts_allow = $hosts_allow
  }

  if $facts['simp_rsync_environments'] and !empty($facts['simp_rsync_environments']) {
    $facts['simp_rsync_environments'].each |String $_env| {

      rsync::server::section { "default_${_env}":
        comment     => "The default file path for Environment: ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/default",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "openldap_server_${_env}":
        auth_users  => ["openldap_rsync_${_env}"],
        comment     => "Configuration for OpenLDAP for Environment: ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/openldap/server",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "bind_dns_default_${_env}":
        auth_users  => ["bind_dns_default_rsync_${_env}"],
        comment     => "Default DNS configurations for named for Environment ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/bind_dns/default",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "apache_${_env}":
        auth_users     => ["apache_rsync_${_env}"],
        comment        => "Apache configurations for Environment ${_env}",
        path           => "${rsync_base}/${_env}/${_rsync_subdir}/apache",
        hosts_allow    => '127.0.0.1',
        outgoing_chmod => 'o-rwx'
      }

      rsync::server::section { "tftpboot_${_env}":
        auth_users  => ["tftpboot_rsync_${_env}"],
        comment     => "Tftpboot server configurations for Environment ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/tftpboot",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "mcafee_${_env}":
        comment     => "McAfee DAT files for Environment ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/mcafee",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "clamav_${_env}":
        comment     => "ClamAV Virus Database Updates for Environment ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/clamav",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "dhcpd_${_env}":
        auth_users  => ["dhcpd_rsync_${_env}"],
        comment     => "DHCP Configurations for Environment ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/dhcpd",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "snmp_${_env}":
        comment     => "SNMP MIBs and Modules for Environment ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/snmp",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "freeradius_${_env}":
        auth_users  => ["freeradius_systems_${_env}"],
        comment     => "Freeradius configuration files for Environment ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/freeradius",
        hosts_allow => $_hosts_allow
      }

      rsync::server::section { "jenkins_plugins_${_env}":
        comment     => "Jenkins Configuration for Environment ${_env}",
        path        => "${rsync_base}/${_env}/${_rsync_subdir}/jenkins_plugins",
        hosts_allow => $_hosts_allow,
      }
    }
  }
  else {
    fail("${module_name} requires the 'simp_rsync_environments' fact to function")
  }
}
