# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# The SIMP Scenario
#
# This configuration is what is recommended for a full SIMP system and is
# designed to meet or exceed the compliance mapped public standards.
#
# For additional details on how to make global changes within the SIMP
# framework, please see the ``simp_options`` module documentation
# http://www.puppetmodule.info/github/simp/pupmod-simp-simp_options/master/
#
class simp::scenario::simp {
  assert_private()

  include 'simp::scenario::base'

  include 'aide'
  include 'auditd'
  # Virus scanning
  include 'clamav'
  # Rootkit checking
  include 'chkrootkit'
  # Ensuring reasonably sane defaults
  include 'at'
  include 'cron'
  include 'fips'
  include 'incron'
  include 'useradd'
  include 'resolv'
  include 'nsswitch'
  include 'issue'
  include 'tuned'
  include 'swap'
  include 'timezone'
  include 'ntpd'
  # Set up the access.conf basics, allow root locally and deny everyone else
  # from everywhere by default.
  include 'pam::access'
  # Enable 'wheel' access controls
  include 'pam::wheel'
  # Configure the Puppet agent
  include 'pupmod'
  # Local syslog with the option to expand to a full server
  include 'simp_rsyslog'
  include 'selinux'
  # Set up the administrators group
  include 'simp::admin'
  # A collection of applications that may be useful on most servers but are not
  # actually required for base functionality.
  include 'simp::base_apps'
  # A group of services that you probably want running but are
  # technically optional.
  include 'simp::base_services'
  # simp::yum sets up an update schedule.
  # You should set variables under the simp::yum::schedule namespace to
  # disable updates from specific repositories.
  include 'simp::yum'
  # Blacklists several kernel modules, per compliance guidelines.
  include 'simp::kmod_blacklist'
  # Manage mountpoints, including all tmp dirs on the system
  include 'simp::mountpoints'
  # Set common and recommended sysctl settings
  include 'simp::sysctl'
  # Set up the SSH server and client
  include 'ssh'
  include 'sudosh'
  # Ensure that only services that are defined in Puppet are going to be enabled and run
  include 'svckill'
}
