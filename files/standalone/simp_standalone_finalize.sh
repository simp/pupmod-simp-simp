#!/bin/bash

usage="Usage: $0 -k (true|false*) -d (true|false*) -f (true*|false) -p (true*|false) [-h] [-d]"

# Option Defaults
remove_pki=1
remove_puppet=0
remove_script=0
dry_run=

while getopts "k:d:p:f:h" opt; do
  case $opt in
    k)
      [[ $OPTARG = 'true' ]] && remove_pki=0 || remove_pki=1
      ;;
    d)
      [[ $OPTARG = 'true' ]] && dry_run='echo' || dry_run=
      ;;
    p)
      [[ $OPTARG = 'true' ]] && remove_puppet=0 || remove_puppet=1
      ;;
    f)
      [[ $OPTARG = 'true' ]] && remove_script=0 || remove_script=1
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
  -k  Remove the SIMP host PKI from the system
  -p  Remove the 'puppet' package from the system
  -f  Remove `basename $0` from the system
  -d  Show all commands but don't execute them (Dry Run)
  -h  This message
EOM

      exit 0
      ;;
  esac
done

if [ -z $dry_run ]; then
  set -x
else
  echo "Executing in Dry Run Mode"
fi

$dry_run cat << EOF > /etc/motd
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

if [ $remove_puppet -eq 0 ]; then
  $dry_run puppet resource cron puppetagent ensure=absent
  $dry_run puppet resource service puppet ensure=stopped

  # Wait for puppet to stop running before we apply the rest of this script
  while [ `/bin/ps h -fC puppet | /bin/grep -ce "puppet \(agent\|apply\)"` -gt 0 ]; do
    /bin/sleep 5;
  done

  $dry_run puppet resource cron pe-mcollective-metadata ensure=absent
  $dry_run puppet resource cron refresh-mcollective-metadata ensure=absent
  $dry_run puppet resource cron puppetagent ensure=absent
  $dry_run puppet resource cron yum_update ensure=absent

  $dry_run yum remove -y puppet puppet-agent puppetlabs*

  $dry_run rm -f /usr/local/bin/puppet*
  $dry_run rm -rf /opt/puppetlabs
  $dry_run rm -f /root/puppet*
  $dry_run rm -f /root/runpuppet
fi

$dry_run yum remove -y simp simp-adapter rubygem-simp-cli

# Remove all SIMP repos
$dry_run rm -f /etc/yum.repos.d/simp*.repo
$dry_run rm -f /usr/local/sbin/update_aide
$dry_run rm -rf /etc/simp

# Remove random SIMP apps
$dry_run rm -rf /usr/local/sbin/simp

if [ $remove_pki -eq 0 ]; then
  $dry_run rm -rf /etc/pki/simp
  $dry_run rm -rf /etc/pki/simp_apps
fi

if [ $remove_script -eq 0 ]; then
  $dry_run rm -f $0
fi
