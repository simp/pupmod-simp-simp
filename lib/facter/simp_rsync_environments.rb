# simp_rsync_environments
#
# A particularly SIMP-specific fact for finding rsync shares on the system
#
# @return [Hash] Rsync shares under `/var/simp/environments/simp/rsync`
#
#   * Is confined on the presence of this directory.
#   * If you want to use a different directory, you'll need to create another
#     fact with a higher weight than this one.
#
# @author Trevor Vaughan - tvaughan@onyxpoint.com
#
Facter.add('simp_rsync_environments') do
  environments = File.join('', 'var', 'simp', 'environments')

  confine do
    File.directory?(environments)
  end

  has_weight 1

  setcode do
    environment_hash = {}

    orig_dir = Dir.pwd

    Dir.chdir(environments)

    Dir.glob('*/rsync').each do |env_dir|

      # Using this instead of Ruby's Find for symlink support
      share_dirs = Facter::Core::Execution.exec("find -L #{File.dirname(env_dir)} -name '.shares'").split("\n").sort

      share_dirs.each do |share_dir|
        Dir.glob(File.join(File.dirname(share_dir),'*')).each do |share|
          dir_parts = share.split('/')

          last = nil
          dir_parts.each_with_index do |p,i|
            key = p.downcase

            if dir_parts[i+2]
              if last
                if last.is_a?(Hash)
                  last[key] ||= {}
                  last[key]['id'] = p
                  last = last[key]
                end
              else
                environment_hash[key] ||= {}
                environment_hash[key]['id'] = p
                last = environment_hash[key]
              end
            else
              if last.is_a?(Hash)
                # We need to add an 'id' value to the Hash because Facter
                # downcases all Hash keys
                last[key] ||= {}
                last[key]['id'] = p
                last[key]['shares'] ||= []
                last[key]['shares'] << dir_parts[i+1]
              end

              break
            end
          end
        end
      end
    end

    Dir.chdir(orig_dir)

    environment_hash
  end
end
