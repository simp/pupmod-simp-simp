# spectre_patched
#
# Returns whether or not the spectre and meltdown updates have
# been applied to the system.  If they have been and the kernel/etc/portreserve directory is empty
#
# @return [Boolean] True if /etc/portreserve has content, false otherwise
#
#   * Is confined on the presence of this directory.
#
# @author Trevor Vaughan - tvaughan@onyxpoint.com
#
Facter.add('spectre_v2') do
  confine :kernel => 'linux'

  setcode do
    File.exists?('/sys/kernel/debug/x86/ibrs_enabled')
  end
end
