# This class hooks the signing of Puppet clients into the creation of FakeCA
# certificates for the associated hosts.
#
# @param delete_on_removal
#   Remove the client certificate from the FakeCA when it is removed from the
#   Puppet CA
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class simp::server::auto_fakeca (
  Boolean $delete_on_removal = true
) {
  include 'incron'

  $_hook_name = 'simp_fakeca_incron_hook'
  $_incron_hook = "/usr/local/sbin/${_hook_name}"

  file { $_incron_hook:
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
    source => "puppet:///modules/${module_name}/${_incron_hook}"
  }

  if $facts['puppet_settings'] {
    if $facts['puppet_settings']['ca'] {
      if $facts['puppet_settings']['ca']['signeddir'] {
        if $delete_on_removal {
          $_incron_mask = ['IN_CREATE', 'IN_DELETE']
        }
        else {
          $_incron_mask = ['IN_CREATE']
        }

        incron::system_table { 'hook_fakeca_to_puppet':
          path    => $facts['puppet_settings']['ca']['signeddir'],
          mask    => $_incron_mask,
          command => "${_incron_hook} \$% \$#",
          require => File[$_incron_hook]
        }
      }
    }
  }
  else {
    warning('The `puppet_settings` fact was not found, `simp::server::auto_fakeca` will have no effect')
  }
}
