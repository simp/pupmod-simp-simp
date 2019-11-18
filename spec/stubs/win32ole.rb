# From https://github.com/chef-cookbooks/chef-client/issues/212#issuecomment-286386195
#
# Need to stub this out for the Windows spec tests
class WIN32OLE
  def self.connect(_name)
    Class.new do
      def self.ExecQuery(_name)
        []
      end
    end
  end
end
