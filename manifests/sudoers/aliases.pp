#
class simp::sudoers::aliases (
  Array[AbsolutePath] $audit_alias = [
    '/bin/cat',
    '/bin/ls',
    '/usr/bin/lsattr',
    '/sbin/aureport',
    '/sbin/ausearch',
    '/sbin/lspci',
    '/sbin/lsusb',
    '/sbin/lsmod',
    '/usr/sbin/lsof',
    '/bin/netstat',
    '/sbin/ifconfig -a',
    '/sbin/route ""',
    '/sbin/route -[venC]',
    '/usr/bin/getent',
    '/usr/bin/tail'
  ],
  Array[AbsolutePath] $delegating_alias = [
    '/usr/sbin/visudo',
    '/bin/chown',
    '/bin/chmod',
    '/bin/chgrp'
  ],
  Array[AbsolutePath] $drivers_alias = [
    '/sbin/modprobe'
  ],
  Array[AbsolutePath] $locate_alias = [
    '/usr/sbin/updatedb'
  ],
  Array[AbsolutePath] $networking_alias = [
    '/sbin/route',
    '/sbin/ifconfig',
    '/bin/ping',
    '/sbin/dhclient',
    '/usr/bin/net',
    '/sbin/iptables',
    '/usr/bin/rfcomm',
    '/usr/bin/wvdial',
    '/sbin/iwconfig',
    '/sbin/mii-tool'
  ],
  Array[AbsolutePath] $processes_alias = [
    '/bin/nice',
    '/bin/kill',
    '/usr/bin/kill',
    '/usr/bin/killall'
  ],
  Array[AbsolutePath] $services_alias = [
    '/sbin/service',
    '/sbin/chkconfig'
  ],
  Array[AbsolutePath] $selinux_alias = [
    '/sbin/restorecon',
    '/usr/bin/audit2why',
    '/usr/bin/audit2allow',
    '/usr/sbin/getenforce',
    '/usr/sbin/setenforce',
    '/usr/sbin/setsebool'
  ],
  Array[AbsolutePath] $software_alias = [
    '/bin/rpm',
    '/usr/bin/up2date',
    '/usr/bin/yum'
  ],
  Array[AbsolutePath] $storage_alias = [
    '/sbin/fdisk',
    '/sbin/sfdisk',
    '/sbin/parted',
    '/sbin/partprobe',
    '/bin/mount',
    '/bin/umount'
  ],
  Array[AbsolutePath] $su_alias = [ '/bin/su' ]
) {

  sudo::alias::cmnd {
    'audit':
      comment => 'System Audit Related Commands',
      content => $audit_alias;
    'delegating':
      comment => 'Delegating System Permissions',
      content => $delegating_alias;
    'drivers':
      comment => 'Driver Manipulation',
      content => $drivers_alias;
    'locate':
      comment => 'Updating Slocate',
      content => $locate_alias;
    'networking':
      comment => 'Useful Networking Commands',
      content => $networking_alias;
    'processes':
      comment => 'Process Manipulation',
      content => $processes_alias;
    'services':
      comment => 'Service Management',
      content => $services_alias;
    'selinux':
      comment => 'SELinux Management and Troubleshooting',
      content => $selinux_alias;
    'software':
      comment => 'Installation and Management of Software',
      content => $software_alias;
    'storage':
      comment => 'Storage Related Commands',
      content => $storage_alias;
    'su':
      content => $su_alias
  }

}