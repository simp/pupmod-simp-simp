# A SIMP profile for using the nsswitch module to manage /etc/nsswitch
#
# @param ldap SIMP global catalyst to enable LDAP
# @param sssd SIMP global catalyst to enable sssd
#
# @note  This class uses trinklin/nsswitch module.
#
class simp::nsswitch (
  Boolean $ldap = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Boolean $sssd = simplib::lookup('simp_options::sssd', { 'default_value' => false })
) {

  simplib::assert_metadata( $module_name )

  $_hosts = $facts['os']['release']['major'] ? {
    6       => ['files','myhostname','dns'],
    default => ['files','dns']
  }

  # define some SIMP defaults
  $default_params = {
    passwd     => ['files'],
    shadow     => ['files'],
    group      => ['files'],
    sudoers    => ['files'],
    hosts      => $_hosts,
    bootparams => ['nisplus','[NOTFOUND=return]','files'],
    ethers     => ['files'],
    netmasks   => ['files'],
    networks   => ['files'],
    protocols  => ['files'],
    rpc        => ['files'],
    services   => ['files'],
    netgroup   => ['files'],
    publickey  => ['nisplus'],
    automount  => ['files','nisplus'],
    aliases    => ['files','nisplus'],
  }

  # if we're using sssd, configure as such
  if $sssd {
    $sssd_options = {
      group    => ['files','[!NOTFOUND=return]','sss'],
      netgroup => ['files','[!NOTFOUND=return]','sss'],
      passwd   => ['files','[!NOTFOUND=return]','sss'],
      shadow   => ['files','[!NOTFOUND=return]','sss'],
      sudoers  => ['files','[!NOTFOUND=return]','sss'],
    }
    $options = $default_params + $sssd_options
  }
  elsif $ldap {
    $ldap_options = {
      group    => ['files','[!NOTFOUND=return]','ldap'],
      netgroup => ['files','[!NOTFOUND=return]','ldap'],
      passwd   => ['files','[!NOTFOUND=return]','ldap'],
      shadow   => ['files','[!NOTFOUND=return]','ldap'],
      sudoers  => ['files','[!NOTFOUND=return]','ldap'],
    }
    $options = $default_params + $ldap_options
  }
  else {
    $options = {}
  }

  class { '::nsswitch':
    * => $default_params + $options
  }
}
