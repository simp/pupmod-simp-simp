# Set up various rsync services that are needed by the SIMP clients
#
# If you don't have these provided somewhere, many of the modules will not
# function properly.
#
# If you want additional ``BIND DNS`` spaces to be served out from rsync,
# you'll need to enable them separately.
#
# This module is directly dependent on the output of the
# ``simp_rsync_environments`` fact which discovers the location, and layout, of
# the facts on the hosting system. The shares **will not** be activated if the
# directory structure is not properly discovered.
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
  Stdlib::Absolutepath $rsync_base         = '/var/simp/environments',
  Optional[Hash]       $rsync_environments = $facts['simp_rsync_environments'],
  Boolean              $stunnel            = simplib::lookup('simp_options::stunnel', { 'default_value' => false }),
  Simplib::Netlist     $trusted_nets       = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
){

  simplib::assert_metadata( $module_name )

  include '::rsync::server'

  if $rsync_environments and !empty($rsync_environments) {

    if $stunnel {
      $_trusted_nets = ['127.0.0.1']
    }
    else {
      $_trusted_nets = $trusted_nets
    }

    # Puppet lint doesn't like lambdas
    # https://github.com/rodjek/puppet-lint/issues/549
    # lint:ignore:variable_scope
    # Process each environment that was found
    (keys($rsync_environments) - ['id']).each |String $_env| {

      # Do the Global items first
      if $rsync_environments[$_env]['rsync']['global'] {
        $_globals_dir   = 'rsync/Global'
        $_global_shares = $rsync_environments[$_env]['rsync']['global']['shares']

        if 'clamav' in $_global_shares {
          rsync::server::section { "clamav_${_env}":
            comment     => "ClamAV Virus Database Updates for Environment ${_env}",
            path        => "${rsync_base}/${_env}/${_globals_dir}/clamav",
            hosts_allow => $_trusted_nets
          }
        }

        if 'mcafee' in $_global_shares {
          rsync::server::section { "mcafee_${_env}":
            comment     => "McAfee DAT files for Environment ${_env}",
            path        => "${rsync_base}/${_env}/${_globals_dir}/mcafee",
            hosts_allow => $_trusted_nets
          }
        }

        if 'jenkins_plugins' in $_global_shares {
          rsync::server::section { "jenkins_plugins_${_env}":
            comment     => "Jenkins Configuration for Environment ${_env}",
            path        => "${rsync_base}/${_env}/${_globals_dir}/jenkins_plugins",
            hosts_allow => $_trusted_nets
          }
        }
      }

      # OS Specific Items
      (keys($rsync_environments[$_env]['rsync']) - ['global','id']).each |String $_os| {
        $_os_id = $rsync_environments[$_env]['rsync'][$_os]['id']

        # OS Major Version Specific Items
        (keys($rsync_environments[$_env]['rsync'][$_os]) - ['global','id']).each |String $_os_maj_ver| {
          $_os_maj_ver_id     = $rsync_environments[$_env]['rsync'][$_os][$_os_maj_ver]['id']
          $_os_maj_ver_shares = $rsync_environments[$_env]['rsync'][$_os][$_os_maj_ver]['shares']

          if 'bind_dns' in $_os_maj_ver_shares {
            rsync::server::section { "bind_dns_default_${_env}_${_os_id}_${_os_maj_ver_id}":
              auth_users  => ["bind_dns_default_rsync_${_env}_${_os_id}_${_os_maj_ver_id}"],
              comment     => "Default DNS configurations for named for Environment ${_env} on ${_os_id} ${_os_maj_ver_id}",
              path        => "${rsync_base}/${_env}/rsync/${_os_id}/${_os_maj_ver_id}/bind_dns/default",
              hosts_allow => $_trusted_nets
            }
          }
        }

        # OS Global Items
        $_os_global_shares = $rsync_environments[$_env]['rsync'][$_os]['global']['shares']

        if 'apache' in $_os_global_shares {
          rsync::server::section { "apache_${_env}_${_os_id}":
            auth_users     => ["apache_rsync_${_env}_${_os}"],
            comment        => "Apache configurations for Environment ${_env} on ${_os}",
            path           => "${rsync_base}/${_env}/rsync/${_os_id}/Global/apache",
            hosts_allow    => $_trusted_nets,
            outgoing_chmod => 'o-rwx'
          }
        }

        if 'tftpboot' in $_os_global_shares {
          rsync::server::section { "tftpboot_${_env}_${_os_id}":
            auth_users  => ["tftpboot_rsync_${_env}_${_os}"],
            comment     => "Tftpboot server configurations for Environment ${_env} on ${_os}",
            path        => "${rsync_base}/${_env}/rsync/${_os_id}/Global/tftpboot",
            hosts_allow => $_trusted_nets
          }
        }

        if 'dhcpd' in $_os_global_shares {
          rsync::server::section { "dhcpd_${_env}_${_os_id}":
            auth_users  => ["dhcpd_rsync_${_env}_${_os}"],
            comment     => "DHCP Configurations for Environment ${_env} on ${_os}",
            path        => "${rsync_base}/${_env}/rsync/${_os_id}/Global/dhcpd",
            hosts_allow => $_trusted_nets
          }
        }

        if 'snmp' in $_os_global_shares {
          rsync::server::section { "snmp_${_env}_${_os_id}":
            comment     => "SNMP MIBs and Modules for Environment ${_env} on ${_os}",
            path        => "${rsync_base}/${_env}/rsync/${_os_id}/Global/snmp",
            hosts_allow => $_trusted_nets
          }
        }

        if 'freeradius' in $_os_global_shares {
          rsync::server::section { "freeradius_${_env}_${_os_id}":
            auth_users  => ["freeradius_systems_${_env}_${_os}"],
            comment     => "Freeradius configuration files for Environment ${_env} on ${_os}",
            path        => "${rsync_base}/${_env}/rsync/${_os_id}/Global/freeradius",
            hosts_allow => $_trusted_nets
          }
        }
      }
    }
    # lint:endignore
  }
}
