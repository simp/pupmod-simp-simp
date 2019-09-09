# From https://github.com/chef-cookbooks/chef-client/issues/212#issuecomment-286386195
#
# Need to stub this out for the Windows spec tests
class Win32::Resolv
  def self.get_hosts_path
    '/etc/hosts'
  end

  def self.get_resolv_info
    'stub'
  end
end
