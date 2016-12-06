#
# simp_rsync_environments
#
# @return [Array] Supported environments under `/var/simp/rsync/environments`
#
#   * Is confined on the presence of this directory.
#   * If you want to use a different directory, you'll need to create another
#     fact with a higher weight than this one.
#
# @author Trevor Vaughan - tvaughan@onyxpoint.com
#
Facter.add('simp_rsync_environments') do
  _rsync_environments = File.join('', 'var', 'simp', 'rsync', 'environments')

  confine do
    File.directory?(_rsync_environments)
  end

  has_weight 1

  setcode do
    Dir.glob(File.join(_rsync_environments, '*')).map{|x| x = File.basename(x)}
  end
end
