# Manage common GRUB attributes
#
# Advanced configuration will need to use the `augeasproviders_grub` components
# directly.
#
# @param password
#   The GRUB administrative password, if not in the hashed form, will be
#   converted for you.
#
#   If a password starts with '$1$', '$5$', or '$6$' then it is assumed to be
#   encrypted.
#
# @param admin
#   The administrative username GRUB 2 systems.
#
# @param purge_unmanaged_users
#   Remove users from GRUB 2 systems that are not managed by Puppet.
#
# @param report_unmanaged_users
#   Report on any unmanaged users on GRUB 2 systems.
#
# @param hash_rounds
#   The rounds to use when hashing the password for GRUB 2 systems.
#
# @author https://github.com/simp/pupmod-simp-simp/contributors
class simp::grub (
  String[1]             $password,
  Optional[String[1]]   $admin                  = undef,
  Optional[Boolean]     $purge_unmanaged_users  = undef,
  Optional[Boolean]     $report_unmanaged_users = undef,
  Optional[Integer[10]] $hash_rounds            = undef
) {
  simplib::assert_metadata($module_name)

  $_grub_version = $facts['augeasprovider_grub_version']

  if $_grub_version == 1 {
    # MD5, SHA512, and SHA256
    #
    # Can't use `grub_config` for MD5 since it appears to overwrite the target
    # file instead of following the symlink.
    if $password[0,3] in ['$1$', '$5$', '$6$'] {
      $_password = $password
    }
    else {
      $_password = pw_hash(
        $password,
        'SHA-512',
        fqdn_rand_string(8, undef, $facts['fqdn'])
      )
    }

    # Passwords might have slashes in them and this doesn't work with sed
    $_safe_hash = regsubst($_password, '/', '\/', 'G')

    # The grub_config native type doesn't handle new-style encrypted
    # passwords properly
    exec { 'Set Grub Password':
      command => "true && ( grep -q '^password ' /etc/grub.conf && sed -i --follow-symlinks 's/^password .*/password --encrypted ${_safe_hash}/' /etc/grub.conf ) || sed -i --follow-symlinks '/^default=.*/a password --encrypted ${_safe_hash}' /etc/grub.conf",
      unless  => "grep -qx 'password --encrypted ${_password}' /etc/grub.conf",
      path    => ['/bin/', '/usr/bin']
    }
  }
  elsif $_grub_version == 2 {
    unless($admin) {
      fail('You must pass "$admin" on GRUB 2 systems')
    }

    grub_user { $admin:
      password         => $password,
      superuser        => true,
      report_unmanaged => $report_unmanaged_users,
      purge            => $purge_unmanaged_users,
      rounds           => $hash_rounds
    }
  }
  else {
    fail("GRUB Version '${_grub_version}' is not supported")
  }
}
