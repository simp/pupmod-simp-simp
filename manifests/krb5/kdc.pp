# == Class: simp::krb5::kdc
#
# A default KDC class that will cover the needs of most users.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::krb5::kdc {
  include 'krb5::kdc'

  # Set up the default realm for the KDC using all of the defaults.
  krb5::kdc::realm { $::domain: }

  # Set up the default admin principal for future use. This will be appropriate
  # for most cases. If you need something different, please use this file as a
  # reference.
  krb5_acl { "${::domain}_admin":
    principal       => "*/admin@${::domain}",
    operation_mask  => '*'
  }
}
