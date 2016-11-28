module Puppet::Parser::Functions
  newfunction(:simp_server_rsync_base, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Find and return a list of rsync served environments.

    This function will return a list of all environments present under the
    passed directory.

    If no directory is passed, it will return all directories under
    '/var/simp/rsync/environments'.
    ENDHEREDOC

    rsync_dir = args[0]

    if rsync_dir
      unless File.directory?(args[0])
        raise(Puppet::ParseError, "simp_server_rsync_base(): could not find rsync base directory at #{args[0]}")
      end
    else
      rsync_dir = '/var/simp/rsync/environments'
    end

    Dir.glob(File.join(rsync_dir, '*'))
  end
end
