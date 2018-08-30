# This class manages the runpuppet script, which is a script that can be run
# to bootstrap provisioned clients, adding them to puppet and running it in a
# fashion similar so `simp bootstrap`.
#
# @param data_dir
#   The location of the web root in which the kickstart directory
#   will reside.  Only used to compute the default for `location`.
#
# @param location
#   The location of the runpuppet file to be placed when generated.
#
# @param ntp_servers
#   An array of ntp servers or hash of server/value pairs that should
#   be used during client kickstarts to slew the local time correctly
#   prior to PKI key distribution.
#
#   Failure to set the system clock will not cause the runpuppet script to fail
#   to execute.
#
# @param puppet_server
#   The FQDN of your Puppet server
#
#   * If not set, will use ``$server_facts['servername']``, or the puppet
#     server set in puppet.conf if trusted_server_facts isn't set or found.
#
# @param puppet_ca
#   The FQDN of your Puppet CA
#
#   * If not set, will use ``$server_facts['servername']``, or the puppet
#     server set in puppet.conf if trusted_server_facts isn't set or found.
#
# @param puppet_ca_port
#   The port upon which the Puppet CA is listening.
#
# @param runpuppet_print_stats
#   If true, print statistics for each client puppet run during bootstrap.
#
# @param runpuppet_wait_for_cert
#   If set to an integer, the runpuppet client script will wait for this many
#   seconds between checking into the puppet master for a signed certificate.
#   This will go on until a signed certificate is presented.
#
#   If set to false or 0, the client will immediately timeout if a signed
#   certificate is not presented.
#
# @param fips
#   If true, set puppet keylength to 2048, else 4096.  This non-compliant
#   setting is to work around problems with older versions of Ruby.  It
#   will be fixed, when Puppet fully supports FIPS mode.
#
class simp::server::kickstart::runpuppet (
  Boolean                     $fips                    = simplib::lookup('simp_options::fips', { 'default_value' => false }),
  Variant[Array, Hash]        $ntp_servers             = simplib::lookup('simp_options::ntpd::servers', { 'default_value' => [] }),
  Optional[Simplib::Host]     $puppet_server           = simplib::lookup('simp_options::puppet::server', { 'default_value' => undef }),
  Optional[Simplib::Host]     $puppet_ca               = simplib::lookup('simp_options::puppet::ca', { 'default_value' => undef }),
  Simplib::Port               $puppet_ca_port          = simplib::lookup('simp_options::puppet::ca_port', { 'default_value' => 8141 }),
  Stdlib::Absolutepath        $data_dir                = simplib::lookup('simp::server::kickstart::data_dir', { 'default_value' => '/var/www'}),
  Stdlib::Absolutepath        $location                = "${data_dir}/ks/runpuppet",
  Boolean                     $runpuppet_print_stats   = true,
  Variant[Integer[0],Boolean] $runpuppet_wait_for_cert = 10
) {

  simplib::assert_metadata( $module_name )

  if $puppet_server {
    $_puppet_server = $puppet_server
  }
  elsif defined('::server_facts') {
    $_puppet_server = $server_facts['servername']
  }
  else {
    $_puppet_server = $facts['puppet_settings']['agent']['server']
  }

  if $puppet_ca {
    $_puppet_ca = $puppet_ca
  }
  elsif defined('::server_facts') {
    $_puppet_ca = $server_facts['servername']
  }
  else {
    $_puppet_ca = $facts['puppet_settings']['agent']['ca_server']
  }

  file { $location:
    ensure  => 'file',
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    content => template("${module_name}/www/ks/runpuppet.erb")
  }

}
