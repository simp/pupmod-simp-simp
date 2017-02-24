# This class manages the runpuppet script, which is a script that can be run
# to bootstrap provisioned systems, adding them to puppet and running it in a
# fashion similar so `simp bootstrap`.
#
# @param data_dir The location of the web root in which runpuppet wil be placed
#
# @param location The absolute location of the runpuppet file to be dropped
#   Use this setting if you're using this module outside of SIMP and are
#   managing another web server for kickstarting.
#
# @param ntp_servers
#   An array of ntp servers or hash of server/vaule pairs that should
#   be used during client kickstarts to slew the local time correctly
#   prior to PKI key distribution.
#
#   Failure to set the system clock will not cause the runpuppet script to fail
#   to execute.
#
# @param puppet_server
#   The FQDN of your Puppet server
#
#   * If not set, will use ``$server_facts['servername']``
#
# @param puppet_ca
#   The FQDN of your Puppet CA
#
#   * If not set, will use ``$server_facts['servername']``
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
#   If set to '' or 0, the client will immediately timeout if a signed
#   certificate is not presented.
#
# @param fips
#   If true, set puppet keylength to 2048, else 4096.
#
class simp::server::kickstart::runpuppet (
  Boolean                     $fips                    = simplib::lookup('simp_options::fips', { 'default_value' => false }),
  Variant[Array, Hash]        $ntp_servers             = simplib::lookup('simp_options::ntpd::servers', { 'default_value' => [] }),
  Optional[Simplib::Host]     $puppet_server           = simplib::lookup('simp_options::puppet::server', { 'default_value' => undef }),
  Optional[Simplib::Host]     $puppet_ca               = simplib::lookup('simp_options::puppet::ca', { 'default_value' => undef }),
  Simplib::Port               $puppet_ca_port          = simplib::lookup('simp_options::puppet::ca_port', { 'default_value' => 8141 }),
  Stdlib::Absolutepath        $data_dir                = '/var/www',
  Stdlib::Absolutepath        $location                = "${data_dir}/ks/runpuppet",
  Boolean                     $runpuppet_print_stats   = true,
  Variant[Integer[0],Boolean] $runpuppet_wait_for_cert = 10
) {

  if $puppet_server {
    $_puppet_server = $puppet_server
  }
  else {
    $_puppet_server = $server_facts['servername']
  }

  if $puppet_ca {
    $_puppet_ca = $puppet_ca
  }
  else {
    $_puppet_ca = $server_facts['servername']
  }

  file { $location:
    ensure  => 'present',
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    content => template("${module_name}/www/ks/runpuppet.erb")
  }

}