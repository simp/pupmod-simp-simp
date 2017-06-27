# portreserve_configured
#
# Returns whether or not the /etc/portreserve directory is empty
#
# @return [Boolean] True if /etc/portreserve has content, false otherwise
#
#   * Is confined on the presence of this directory.
#
# @author Trevor Vaughan - tvaughan@onyxpoint.com
#
Facter.add('portreserve_configured') do
  confine do
    File.directory?('/etc/portreserve')
  end

  has_weight 1

  setcode do
    !Dir.glob('/etc/portreserve/*').empty?
  end
end
