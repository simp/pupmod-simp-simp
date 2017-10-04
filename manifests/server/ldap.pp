# Sets up either a primary LDAP server or a slave LDAP server.
#
# If you are setting up a slave LDAP server, remember that the three
# digit RID must be unique or each slave server that you attach to the
# same master.
#
# @param is_slave
#   If true, set this node up as an LDAP slave. The Hiera parameter
#   ldap::master will be used as the master server.
#
#   If you want to use values other than the defaults as provided with
#   simp_openldap::server::syncrepl. Leave this as 'false', include this
#   class and call simp_openldap::server::syncrepl with your values as
#   appropriate.
#
# @param rid
#   The RID of the system. See simp_openldap::server::syncrepl for
#   additional information.
#
# @param bind_dn
#   Used for setting up sync limits for the bind user.
#
# @param sync_dn
#   Used for setting up sync limits for slave nodes.
#
# @param enable_lastbind
#   If true, enable the 'lastbind' plugin for OpenLDAP. This records
#   the last time a user logs into a system within LDAP itself. Note,
#   if you have auditing enabled, this will cause an LDAP audit record
#   every time someone logs into any system connected to the LDAP
#   server.
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::server::ldap (
  Boolean    $is_slave        = false,
  Integer[0] $rid             = 111,
  String     $bind_dn         = simplib::lookup('simp_options::ldap::bind_dn', { 'default_value' => '' }),
  String     $sync_dn         = simplib::lookup('simp_options::ldap::sync_dn', { 'default_value' => '' }),
  Boolean    $enable_lastbind = false
){

  simplib::assert_metadata( $module_name )

  # Order matters with these top two!
  include '::simp_openldap'
  include '::simp_openldap::server'
  include '::simp_openldap::slapo::ppolicy'
  include '::simp_openldap::slapo::syncprov'
  if $enable_lastbind { include '::simp_openldap::slapo::lastbind' }

  $s_rid = to_string($rid)
  if $is_slave {
    simp_openldap::server::syncrepl { $s_rid: }
  }

  if !empty($bind_dn) {
    simp_openldap::server::limits { 'Host_Bind_DN_Unlimited_Query':
      who    => $bind_dn,
      limits => ['size.soft=unlimited','size.hard=unlimited','size.prtotal=unlimited']
    }
  }

  if !empty($sync_dn) {
    simp_openldap::server::limits { 'LDAP_Sync_DN_Unlimited_Query':
      who    => $sync_dn,
      limits => ['size.soft=unlimited','size.hard=unlimited','size.prtotal=unlimited']
    }
  }
}
