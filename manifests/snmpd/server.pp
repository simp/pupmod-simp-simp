# == Class: simp::snmpd::server
#
# Configure a full-features SNMP server.
#
# This sets up a fairly robust SNMP server.
#
# You can test this out with:
# snmpwalk -v 3 -l authPriv -a SHA -A <monitor_user_auth_phrase> -x AES \
#          -u monitorUser -X <monitor_user_priv_phrase> <hostname>
#
# == Parameters
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::snmpd::server (
  String         $monitor_user_auth_phrase,
  String         $monitor_user_priv_phrase,
  String         $admin_user_auth_phrase,
  String         $admin_user_priv_phrase,
  Array[String]  $allow_from = defined('$::client_nets') ? { true => $::client_nets, default => hiera('client_nets') }
) {
  validate_net_list($allow_from)

  include '::snmpd'
  include '::snmpd::authtrapenable'

  snmpd::agentaddress { 'allowed_hosts':
    allow_from => $allow_from
  }

  snmpd::vacm::group { 'monitorGroup':
    group     => 'monitorGroup',
    sec_model => 'usm',
    secname   => 'monitorUser'
  }

  snmpd::vacm::group { 'adminGroup':
    group     => 'adminGroup',
    sec_model => 'usm',
    secname   => 'adminUser'
  }

  snmpd::vacm::view { 'roView':
    vname => 'roView',
    oid   => '.1'
  }

  snmpd::vacm::view { 'rwView_1':
    vname => 'rwView',
    oid   => 'system.sysContact'
  }

  snmpd::vacm::view { 'rwView_2':
    vname => 'rwView',
    oid   => 'system.sysLocation'
  }

  snmpd::vacm::view { 'rwView_3':
    vname => 'rwView',
    oid   => 'system.sysName'
  }

  snmpd::vacm::view { 'rwView_Config_reread':
    vname => 'rwView',
    oid   => '.1.3.6.1.4.1.2021.100.11.0'
  }

  snmpd::vacm::access { 'monitorGroup':
    group     => 'monitorGroup',
    sec_model => 'usm',
    level     => 'priv',
    read      => 'roView'
  }

  snmpd::vacm::access { 'adminGroup':
    group     => 'adminGroup',
    sec_model => 'usm',
    level     => 'priv',
    read      => 'roView',
    write     => 'rwView'
  }

  snmpd::createuser { 'monitorUser':
    auth_phrase => $monitor_user_auth_phrase,
    priv_phrase => $monitor_user_priv_phrase
  }

  snmpd::createuser { 'adminUser':
    auth_phrase => $admin_user_auth_phrase,
    priv_phrase => $admin_user_priv_phrase
  }
}
