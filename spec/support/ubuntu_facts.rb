# frozen_string_literal: true

# A few classes (see "Limitations" in the README) support Ubuntu, which is not
# listed in metadata.json because the rest of the module does not.
# simp-rspec-puppet-facts only ships EL factsets, so this returns the FacterDB
# factsets for the supported Ubuntu releases.
#
# FacterDB does not carry simplib's custom facts, so the ones these classes
# read are added with the values simplib reports on a stock Ubuntu system.
def ubuntu_facts
  simplib_facts = {
    init_systems: ['rc', 'systemd', 'sysv'],
    simplib_sysctl: {
      'crypto.fips_enabled' => 0,
      'kernel.ctrl-alt-del' => 0,
      'kernel.modules_disabled' => 0,
      'net.ipv6.conf.all.disable_ipv6' => 0,
      'vm.swappiness' => 60,
    },
  }

  Simp::RspecPuppetFacts::Shim.on_supported_os(
    supported_os: [{ 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['22.04', '24.04'] }],
  ).transform_values { |facts| facts.merge(simplib_facts) }
end

# The facts for every OS in metadata.json, plus Ubuntu
def supported_os_and_ubuntu_facts
  on_supported_os.merge(ubuntu_facts)
end
