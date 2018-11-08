#!/usr/bin/env ruby

require json
require tempfile

params = JSON.parse(STDIN.read)

if params['profile'].nil?
  params['profile'] = 'xccdf_org.ssgproject.content_profile_nist-800-171-cui'
end

out = Tempfile.new(File.basename($0))

  case $facts['os']['name'] {
    'RedHat': { $osname = 'rhel' }
    default:  { $osname = $facts['os']['name'].downcase() }
  }
system(
  '/usr/bin/oscap',
  'xccdf',
  'eval',
  '--profile',
  params['profile'],
  '--results',
  out.path(),
  /usr/share/xml/scap/ssg/content/ssg-<%= $osname %><%= $facts['os']['release']['major'] %>-ds.xml
  >/dev/null 2>/dev/null
)
