#!/bin/bash

set -e

profile="${PT_profile:-'xccdf_org.ssgproject.content_profile_nist-800-171-cui'}"

#<%
#  case $facts['os']['name'] {
#    'RedHat': { $osname = 'rhel' }
#    default:  { $osname = $facts['os']['name'].downcase() }
#  }
#-%>

if [ ! -x /usr/bin/oscap ] ; then
    yum -y install openscap-scanner
fi

/usr/bin/oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_nist-800-171-cui --results /var/log/simp/scap/`date +%Y%m%d%H%M%S`.xml /usr/share/xml/scap/ssg/content/ssg-<%= $osname %><%= $facts['os']['release']['major'] %>-ds.xml >/dev/null 2>/dev/null
