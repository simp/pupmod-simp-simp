# spectre_patched
#
# Test if the kernel can handle the spectre_v2 boot param
# by checking if the file it sets exists.
#
# @return [Boolean] True if /sys/kernel/debug/x86/ibrs_enabled
#   exists
#
# @author SIMP Team
#
Facter.add('meltdown') do
  confine :kernel => 'linux'

  setcode do
    File.exists?('/sys/kernel/debug/x86/pti_enabled')
  end
end
