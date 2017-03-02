# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# The SIMP 'Lite' Scenario
#
# This is a minimal configuration that enables the majority of the SIMP
# management components but does not enable some of the items that users have
# found difficult to integrate into legacy infrastructures in the past.
#
# **NOTE** This will **NOT** pass many Certification evaluations for various
# standards but may provide you with an acceptable risk scenario for your
# environment.
#
# Namely, the following items are not included by default (please feel free to
# include the ones that you want as possible:
#
# * firewall
# * fips
# * selinux
# * tcpwrappers
# * svckill
# * PAM host access controls
#
# For additional details on how to make global changes within the SIMP
# framework, please see the ``simp_options`` module documentation
# http://www.puppetmodule.info/github/simp/pupmod-simp-simp_options/master/
#
class simp::scenario::simp_lite {
  assert_private()

  $_simp_options = {
    'firewall'    => false,
    'pam'         => false,
    'selinux'     => false,
    'tcpwrappers' => false
  }

  # Options *must* be set first (or in Hiera/ENC)!
  class { 'simp_options':
    *           => ($::simp::default_options + $_simp_options)
  }

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
  include 'incron'
  include 'useradd'
  include 'resolv'
  include 'nsswitch'
  include 'issue'
  include 'tuned'
  include 'swap'
  include 'timezone'
  include 'ntpd'
  # Configure the Puppet agent
  include 'pupmod'
  # Local syslog with the option to expand to a full server
  include 'simp_rsyslog'
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
}
