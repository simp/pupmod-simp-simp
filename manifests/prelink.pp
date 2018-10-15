# Manage prelinking
#
# @param enable
#   Whether to enable prelinking.  Prelinking can only be enabled if
#   the server is *NOT* in FIPS mode.
#
#   * When ``$enable`` is ``true`` and ``$facts['fips_enabled']`` is
#     ``false``, ensures the prelink package is installed and
#     prelinking has been enabled.
#
#   * When ``$enable`` is ``false`` or ``$facts['fips_enabled']`` is
#     ``true``, ensures the prelink package is not installed, undoing
#     any existing prelinking, if needed.  This satisfies the SCAP
#     Security Guide's OVAL check
#     xccdf_org.ssgproject.content_rule_disable_prelink.
#
# @param ensure
#   The ``$ensure`` status of the prelink package, when ``$enable``
#   is ``true`` and ``$facts['fips_enabled']`` is ``false``.
#
# @author https://github.com/simp/pupmod-simp-simp/graphs/contributors
#
class simp::prelink (
  Boolean $enable = false,
  String  $ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })
) {
  simplib::assert_metadata( $module_name )

  if ( $enable and ! $facts['fips_enabled'] ) {
    package { 'prelink':
      ensure => $ensure
    }

    shellvar { 'enable prelink':
      ensure   => present,
      target   => '/etc/sysconfig/prelink',
      variable => 'PRELINKING',
      value    => 'yes'
    }

    Package['prelink'] ~> Shellvar['enable prelink']
  }
  else {
    if $facts['prelink'] {
      # prelink is installed.  Any prelinking must be undone before
      # removing the prelink package.  The best way to do this is to
      # disable prelinking and then run /etc/cron.daily/prelink (from
      # the installed prelink package).
      if $facts['prelink']['enabled'] {
        shellvar { 'disable prelink':
          ensure   => present,
          target   => '/etc/sysconfig/prelink',
          variable => 'PRELINKING',
          value    => 'no',
          before   => Exec['remove prelinking']
        }
      }

      exec { 'remove prelinking':
        command => '/etc/cron.daily/prelink',
        # before is the resource that *removes* the prelink package
        before  => Package['prelink']
      }

      package { 'prelink':
        ensure => 'absent'
      }
    }
  }
}
