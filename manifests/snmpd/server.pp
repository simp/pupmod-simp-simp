# == Class: simp::snmpd::server
#
# Configure a full-features SNMP server.
#
# This sets up a fairly robust SNMP server.
#
# You can test this out with:
# snmpwalk -v 3 -l authPriv -a SHA -A <monitorUser_auth_phrase> -x AES \
#          -u monitorUser -X <monitorUser_priv_phrase> <hostname>
#
# == Parameters
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::snmpd::server (
  $monitorUser_auth_phrase,
  $monitorUser_priv_phrase,
  $adminUser_auth_phrase,
  $adminUser_priv_phrase,
  $allow_from = defined('$::client_nets') ? { true  => $::client_nets, default =>  hiera('client_nets') }
) {
  include 'snmpd'

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

  include 'snmpd::authtrapenable'

  snmpd::createuser { 'monitorUser':
    auth_phrase => $monitorUser_auth_phrase,
    priv_phrase => $monitorUser_priv_phrase
  }

  snmpd::createuser { 'adminUser':
    auth_phrase => $adminUser_auth_phrase,
    priv_phrase => $adminUser_priv_phrase
  }

  validate_net_list($allow_from)
}
