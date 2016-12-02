# Manages FIPS
#
# @params use_fips Boolean
#   If enabled, the system will be FIPS 140-2 enabled.
#
# @params use_fips_aesni Boolean
#   If enabled and $use_fips is true, then install dracut-fips-aesni
#
class simp::fips (
  Boolean $use_fips       = $::simp::use_fips,
  Boolean $use_fips_aesni = $::cpuinfo and member($::cpuinfo['processor0']['flags'],'aes'),
) {
  if $use_fips {
    kernel_parameter { 'fips':
      value  => '1',
      notify => Reboot_notify['fips']
      # bootmode => 'normal', # This doesn't work due to a bug in the Grub Augeas Provider
    }
    kernel_parameter { 'boot':
      value  => "UUID=${::boot_dir_uuid}",
      notify => Reboot_notify['fips']
      # bootmode => 'normal', # This doesn't work due to a bug in the Grub Augeas Provider
    }
    package { 'dracut-fips':
      ensure => 'latest',
      notify => Exec['dracut_rebuild']
    }
    package { 'fipscheck':
      ensure => 'latest'
    }
    if $use_fips_aesni {
      package { 'dracut-fips-aesni':
        ensure => 'latest',
        notify => Exec['dracut_rebuild']
      }
    }
  }
  else {
    kernel_parameter { 'fips':
      value  => '0',
      notify => Reboot_notify['fips']
      # bootmode => 'normal', # This doesn't work due to a bug in the Grub Augeas Provider
    }
  }

  reboot_notify { 'fips': }

  # If the NSS and dracut packages don't stay reasonably in sync, your system
  # may not reboot.
  package { 'nss': ensure => 'latest' }

  exec { 'dracut_rebuild':
    command     => '/sbin/dracut -f',
    subscribe   => Package['nss'],
    refreshonly => true
  }

}
