#!/bin/bash

set -e -o pipefail

usage="Usage: $0 -k (true|false*) -d (true|false*) -f (true*|false) -p (true*|false) [-D (true|false*)] [-h]"

puppet='/opt/puppetlabs/bin/puppet'

if [ ! -f "${puppet}" ]; then
  puppet=`which puppet`

  if [ -z "${puppet}" ]; then
    echo "Error: could not find 'puppet' command"
    exit 1
  fi
fi

# Option Defaults
remove_pki=1
remove_puppet=0
remove_script=0
enable_debug=1
dry_run=""

while getopts "k:d:p:f:D:h" opt; do
  case $opt in
    k)
      [[ $OPTARG = 'true' ]] && remove_pki=0 || remove_pki=1
      ;;
    d)
      [[ $OPTARG = 'true' ]] && dry_run='echo' || dry_run=""
      ;;
    p)
      [[ $OPTARG = 'true' ]] && remove_puppet=0 || remove_puppet=1
      ;;
    f)
      [[ $OPTARG = 'true' ]] && remove_script=0 || remove_script=1
      ;;
    D)
      [[ $OPTARG = 'true' ]] && enable_debug=0 || enable_debug=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo $usage >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      echo $usage >&2
      exit 1
      ;;
    h)
        cat <<-EOM
$usage
  -k  (true|false*) Remove the SIMP host PKI from the system
  -d  (true|false*) Show all commands but don't execute them (Dry Run)
  -f  (true*|false) Remove `basename $0` from the system
  -p  (true*|false) Remove the 'puppet' package from the system
  -h  This message
EOM

      exit 0
      ;;
  esac
done

function debug() {
  if [ $enable_debug -eq 0 ]; then
    logger "simp_one_shot_finalize.sh: ${1}"
  fi
}

debug "Remove PKI: ${remove_pki}"
debug "Remove Puppet: ${remove_puppet}"
debug "Remove Script: ${remove_script}"
debug "Debug: ${enable_debug}"
debug "Dry Run: ${dry_run}"

if [ -z $dry_run ]; then
  set -x
else
  echo "Executing in Dry Run Mode"
fi

if [ -n $dry_run ]; then
  echo "Update /etc/motd"
else
  debug "Updating MOTD"

  cat << EOF > /etc/motd
This is a SIMP-based standalone image

Some items you should be aware of:
  * To get to 'root', you need to use 'sudo sudosh'
  * IPTables is *on*
  * TCPWrappers is *on*
  * Host access restriction via PAM is *on* (/etc/security/access.conf)
  * Password quality restrictions are *enabled*

PLEASE CHANGE YOUR PASSWORD

You can remove this message by changing /etc/motd
EOF

  debug "MOTD Updated"
fi

if [ -z $dry_run ]; then
  debug "Waiting for puppet to stop"

  # Wait for puppet to stop running before we apply the rest of this script
  while [ `/bin/ps h -fC puppet | /bin/grep -ce "puppet \(agent\|apply\)"` -gt 0 ]; do
    /bin/sleep 5;
  done

  debug "Puppet Stopped"
fi

debug "Removing SIMP packages"
$dry_run $puppet resource package simp ensure=absent
$dry_run $puppet resource package simp-adapter ensure=absent
$dry_run $puppet resource package rubygem-simp-cli ensure=absent
debug "SIMP packages removed"

debug "Disabling SIMP repos"
for repo in `$puppet resource yumrepo --to_yaml | grep -o "simp.*:$" | cut -f1 -d':'`; do
  debug "Disabling repo '${repo}'"
  $dry_run $puppet resource yumrepo "${repo}" enabled=0
  debug "Repo '${repo}' disabled"
done
debug "SIMP repos Disabled"

debug "Removing SIMP artifacts"
$dry_run $puppet resource file /usr/local/sbin/update_aide ensure=absent force=true
$dry_run $puppet resource file /etc/simp ensure=absent force=true

# Remove random SIMP apps
$dry_run $puppet resource file /usr/local/sbin/simp ensure=absent force=true
debug "SIMP artifacts removed"

if [ $remove_pki -eq 0 ]; then
  debug "Removing SIMP PKI"
  $dry_run $puppet resource file /etc/pki/simp ensure=absent force=true
  $dry_run $puppet resource file /etc/pki/simp_apps ensure=absent force=true
  debug "SIMP PKI removed"
fi

if [ $remove_script -eq 0 ]; then
  $dry_run $puppet resource file "${0}" ensure=absent force=true
fi

if [ $remove_puppet -eq 0 ]; then
  debug "Removing puppetagent cron job"
  $dry_run $puppet resource cron puppetagent ensure=absent
  debug "Puppetagent cron job removed"

  debug "Stopping puppet service"
  $dry_run $puppet resource service puppet ensure=stopped
  debug "Puppet service stopped"

  debug "Removing cron jobs"
  $dry_run $puppet resource cron pe-mcollective-metadata ensure=absent
  $dry_run $puppet resource cron refresh-mcollective-metadata ensure=absent
  $dry_run $puppet resource cron yum_update ensure=absent
  debug "Cron jobs removed"

  debug "Removing puppet packages"
  $dry_run $puppet resource package puppet ensure=absent
  $dry_run yum remove -y puppet-agent
  $dry_run yum remove -y puppetlabs*
  debug "Puppet packages removed"

  debug "Removing puppet system artifacts"
  $dry_run rm -f /usr/local/bin/puppet*
  $dry_run rm -rf /opt/puppetlabs
  debug "Puppet system artifacts removed"
fi
