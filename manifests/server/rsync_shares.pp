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
# @param rsync_environments
#   The environments that are present under ``$rsync_base`` on the RSync server.
#
#   Be **VERY** careful if you change this from the fact that it references by
#   default.
#
# @param stunnel If set, trusted_nets will be set to ``127.0.0.1`` so that
#   the stunnel'd rsync will be used.
#
# @param trusted_nets
#   The hosts from which to allow access to the rsync shares. This option has
#   no effect if ``$use_stunnel`` is ``true``.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::server::rsync_shares (
  Stdlib::Absolutepath $rsync_base         = '/var/simp/rsync/environments',
  Optional[Array]      $rsync_environments = $facts["simp_rsync_environments"],
  Boolean              $stunnel            = simplib::lookup('simp_options::stunnel', { 'default_value' => false }),
  Simplib::Netlist     $trusted_nets       = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
){

  include '::rsync::server::global'

  if $rsync_environments {
    $_rsync_subdir = "${facts['operatingsystem']}/${facts['operatingsystemmajrelease']}"

    if $stunnel {
      $_trusted_nets = ['127.0.0.1']
    }
    else {
      $_trusted_nets = $trusted_nets
    }

    $rsync_environments.each |String $_env| {
      rsync::server::section { "default_${_env}":
        comment      => "The default file path for Environment: ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/default",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "openldap_server_${_env}":
        auth_users   => ["openldap_rsync_${_env}"],
        comment      => "Configuration for OpenLDAP for Environment: ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/openldap/server",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "bind_dns_default_${_env}":
        auth_users   => ["bind_dns_default_rsync_${_env}"],
        comment      => "Default DNS configurations for named for Environment ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/bind_dns/default",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "apache_${_env}":
        auth_users     => ["apache_rsync_${_env}"],
        comment        => "Apache configurations for Environment ${_env}",
        path           => "${rsync_base}/${_env}/${_rsync_subdir}/apache",
        trusted_nets   => '127.0.0.1',
        outgoing_chmod => 'o-rwx'
      }

      rsync::server::section { "tftpboot_${_env}":
        auth_users   => ["tftpboot_rsync_${_env}"],
        comment      => "Tftpboot server configurations for Environment ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/tftpboot",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "mcafee_${_env}":
        comment      => "McAfee DAT files for Environment ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/mcafee",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "clamav_${_env}":
        comment      => "ClamAV Virus Database Updates for Environment ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/clamav",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "dhcpd_${_env}":
        auth_users   => ["dhcpd_rsync_${_env}"],
        comment      => "DHCP Configurations for Environment ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/dhcpd",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "snmp_${_env}":
        comment      => "SNMP MIBs and Modules for Environment ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/snmp",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "freeradius_${_env}":
        auth_users   => ["freeradius_systems_${_env}"],
        comment      => "Freeradius configuration files for Environment ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/freeradius",
        trusted_nets => $_trusted_nets
      }

      rsync::server::section { "jenkins_plugins_${_env}":
        comment      => "Jenkins Configuration for Environment ${_env}",
        path         => "${rsync_base}/${_env}/${_rsync_subdir}/jenkins_plugins",
        trusted_nets => $_trusted_nets
      }
    }
  }
}
