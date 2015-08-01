Summary: SIMP Puppet Module
Name: pupmod-simp
Version: 1.1.0
Release: 1
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Requires: pupmod-aide >= 4.1.0-2
Requires: pupmod-apache >= 4.1.0-4
Requires: pupmod-auditd >= 4.1.0-3
Requires: pupmod-augeasproviders_puppet
Requires: pupmod-clamav >= 4.1.0-2
Requires: pupmod-common >= 4.2.0-0
Requires: pupmod-concat >= 4.0.0-0
Requires: pupmod-dhcp >= 4.1.0-0
Requires: pupmod-functions >= 2.1.0-0
Requires: pupmod-iptables >= 4.1.0-3
Requires: pupmod-logrotate >= 4.1.0-0
Requires: pupmod-named >= 4.2.0-0
Requires: pupmod-nscd >= 5.0.0-0
Requires: pupmod-ntpd >= 4.1.0-1
Requires: pupmod-openldap >= 4.1.0-3
Requires: pupmod-pam >= 4.1.0-3
Requires: pupmod-pki >= 4.1.0-0
Requires: pupmod-postfix >= 4.1.0-0
Requires: pupmod-pupmod >= 6.0.0-3
Requires: pupmod-puppetlabs-inifile >= 1.0.0-0
Requires: pupmod-rsync >= 4.1.0-1
Requires: pupmod-rsyslog >= 5.0.0-0
Requires: pupmod-selinux >= 1.0.0-1
Requires: pupmod-ssh >= 4.1.0-2
Requires: pupmod-stunnel >= 4.2.0-0
Requires: pupmod-sudo >= 4.1.0-0
Requires: pupmod-sudosh >= 4.1.0-0
Requires: pupmod-svckill >= 1.0.0-0
Requires: pupmod-sysctl >= 4.1.0-0
Requires: pupmod-tcpwrappers >= 2.1.0-0
Requires: pupmod-tftpboot >= 4.1.0-1
Requires: pupmod-upstart >= 4.1.0-2
Requires: pupmod-xinetd >= 2.1.0-0
Requires: puppetlabs-stdlib >= 4.1.0-1.SIMP
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-simp-test

Prefix: /etc/puppet/environments/simp/modules

%description
This puppet module provides a set of default classes that will be
useful to most users and which form the foundation of the core SIMP
installation.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/simp

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/simp
done

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/simp

%files
%defattr(0640,root,puppet,0750)
%{prefix}/simp

%post
#!/bin/sh

if [ -d %{prefix}/simp/plugins ]; then
  /bin/mv %{prefix}/simp/plugins %{prefix}/simp/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Fri Jul 31 2015 Kendall Moore <kmoore@keywcorp.com> - 1.1.0-1
- Added support for the updated rsyslog module.

* Thu Apr 02 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.1.0-0
- Added PuppetDB support

* Thu Apr 02 2015 Nick Markowski <nmarkowski@keywcorp.com> - 1.0.0-7
- Modified runpuppet script to ensure the puppetserver service is running
  before puppet runs.

* Thu Feb 19 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-6
- Migrated to the new 'simp' environment.

* Wed Jan 14 2015 Nick Markowski <nmarkowski@keywcorp.com> - 1.0.0-6
- Re-created the MCollective stock class, now with SSL fully enabled.

* Tue Nov 25 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-5
- Updated the default GPG key list.
- Updated the rsyslog stock classes to remove stunnel support and,
  instead, take advantage of the native TLS support in rsyslog.
- NOTE: This requires changing the global 'log_server' variable in
  Hiera to a 'log_servers' Array which is done in the %post section of
  this RPM.

* Thu Nov 06 2014 Chris Tessmer <chris.tessmer@onyxpoint.com> - 1.0.0-5
- Removed sssd::conf as it is no longer needed and causes duplicate
  concat_fragment error

* Fri Oct 31 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-4
- Moved the mcollective IPTables and package material into the main
  SIMP module.
- Update to account for the stunnel module updates in 4.2.0-0

* Fri Sep 19 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-3
- Updated the nfs::home_client class to properly account for the port
  setting in the mounts.

* Tue Aug 19 2014 Nick Markowski <nmarkowski@keywcorp.com> - 1.0.0-2
- Differentiated the rsync module paths between 4.X and 5.X distributions.
  4.X should not include the distribution and release in the path.

* Mon Aug 18 2014 Kendall Moore <kmoore@keywcorp.com> - 1.0.0-2
- Updated the digest_algorithm in the runpuppet script to be SHA-256.

* Fri Aug 08 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-1
- Ensure that runpuppet returns '1' when queried for status so that
  svckill doesn't continually attempt to disable it.

* Fri Jul 25 2014 Nick Markowski <nmarkowski@keywcorp.com> - 1.0.0-0
- Ensured /srv/www/yum/SIMP is created if SIMP version < 5.

* Mon Jul 21 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-0
- /var/nfs is used for NFS in SIMP>=5 and /srv/nfs otherwise
- Updated yum and kickstart to use /var/www if SIMP>=5 and /srv/www
  otherwise

* Mon Jul 21 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-4
- Updated to use the new rsync path.

* Tue Jul 15 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-4
- Updated to support the RHEL7 repo GPG keys.

* Tue Jul 15 2014 Kendall Moore <kmoore@keywcorp.com> - 0.0.1-4
- Added CentOS as a supported OS as a part of CentOS 7 upgrade.

* Thu Jun 19 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-3
- Separated out the RHEL6/7 package requirements appropriately.

* Thu Jun 12 2014 Nick Markowski <nmarkowski@keywcorp.com> - 0.0.1-2
- Ntp servers can be passed to kickstart as an array of server names
  or a hash of server => 'option' pairs.

* Fri May 16 2014 Kendall Moore <kmoore@keywcorp.com> - 0.0.1-1
- Added stock classes for FreeRADIUS
- Added stock classes for Ganglia
- Added stock classes for RSyslog
- Added stock classes for krb5
- Added stock classes for MRepo
- Added stock classes for SNMP

* Tue May 13 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-1
- Added a quiet_puppet variable to runpuppet for the cert download
  segment.

* Mon May 05 2014 Kendall Moore <kmoore@keywcorp.com> - 0.0.1-0
- Added stock classes for NFS home directories.

* Fri Mar 21 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-0
- Initial Release
- Ported all materials from the old default_classes directory.
- Incorporated several parts of sec and common as appropriate to the
  separation of duties.
