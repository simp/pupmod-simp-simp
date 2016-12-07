# == Class: simp::ldap_server
#
# Sets up either a primary LDAP server or a slave LDAP server.
#
# If you are setting up a slave LDAP server, remember that the three
# digit RID must be unique or each slave server that you attach to the
# same master.
#
# == Parameters
#
# [*is_slave*]
# Type: Boolean
# Default: false
#   If true, set this node up as an LDAP slave. The Hiera parameter
#   ldap::master will be used as the master server.
#
#   If you want to use values other than the defaults as provided with
#   openldap::server::syncrepl. Leave this as 'false', include this
#   class and call openldap::server::syncrepl with your values as
#   appropriate.
#
# [*rid*]
# Type: Integer between 1 and 999, inclusive.
# Default: 111
#   The RID of the system. See openldap::server::syncrepl for
#   additional information.
#
# [*bind_dn*]
# Type: LDAP DN
# Default: hiera('ldap::bind_dn')
#   Used for setting up sync limits for the bind user.
#
# [*sync_dn*]
# Type: LDAP DN
# Default: hiera('ldap::sync_dn')
#   Used for setting up sync limits for slave nodes.
#
# [*enable_lastbind*]
# Type: Boolean
# Default: false
#   If true, enable the 'lastbind' plugin for OpenLDAP. This records
#   the last time a user logs into a system within LDAP itself. Note,
#   if you have auditing enabled, this will cause an LDAP audit record
#   every time someone logs into any system connected to the LDAP
#   server.
#
# == Authors
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::ldap_server (
  Boolean                 $is_slave        = false,
  Stdlib::Compat::Integer $rid             = '111',
  String                  $bind_dn         = defined('$::bind_dn') ? { true => $::bind_dn, default => hiera('bind_dn','') },
  String                  $sync_dn         = defined('$::sync_dn') ? { true => $::sync_dn, default => hiera('sync_dn','') },
  Boolean                 $enable_lastbind = false
){

  # Order matters with these top two!
  include '::openldap'
  include '::openldap::server'
  include '::openldap::slapo::ppolicy'
  include '::openldap::slapo::syncprov'
  if $enable_lastbind { include '::openldap::slapo::lastbind' }

  if $is_slave {
    openldap::server::syncrepl { $rid: }
  }

  if !empty($bind_dn) {
    openldap::server::add_limits { 'Host_Bind_DN_Unlimited_Query':
      who    => $bind_dn,
      limits => ['size.soft=unlimited','size.hard=unlimited','size.prtotal=unlimited']
    }
  }

  if !empty($sync_dn) {
    openldap::server::add_limits { 'LDAP_Sync_DN_Unlimited_Query':
      who    => $sync_dn,
      limits => ['size.soft=unlimited','size.hard=unlimited','size.prtotal=unlimited']
    }
  }
}
