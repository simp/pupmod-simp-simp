# This class manages the runpuppet script, which is a script that can be run
# to bootstrap provisioned clients, adding them to puppet and running it in a
# fashion similar so `simp bootstrap`.
#
# @param location The location of the runpuppet file to be placed when
#   generated.
#
#   *  The bootstrap_simp_client script used by runpuppet will
#      be placed in the same directory of the runpuppet file.
#
# @param ntp_servers
#   An array of ntp servers or hash of server/value pairs that should
#   be used during client kickstarts to slew the local time correctly
#   prior to PKI key distribution.
#
#   **NOTE**: Failure to set the system clock will not cause the runpuppet
#   script to fail to execute.
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
# @param puppet_digest_algorithm
#   The digest algorithm Puppet uses for file resources and the filebucket
#   (e.g. sha256, sha384, sha512).
#
# @param puppet_keylength
#   Puppet certificate keylength.  When unset, value is determined based
#   on `$fips`, to work around Puppet bugs in FIPS mode.  (See `$fips`.)
#
# @param num_puppet_runs
#   Number of puppet agent runs (after the initial tagged run) to execute,
#   in order to converge to a stable system configuration.
#
# @param initial_retry_interval
#   Initial retry interval in seconds for reattempting a failed puppet
#   agent run.
#
# @param retry_factor
#   The factor to be applied to the retry interval for a puppet run.
#   The retry interval is multiplied by this factor for each retry.
#   For example, if `$initial_retry_interval` is 10 and the retry factor
#   is 1.5, the first retry would occur 10 seconds after the initial
#   attempt, the second retry would occur 10*1.5 seconds after that,
#   the third retry would occur 10*1.5*1.5 seconds after that, etc.
#
# @param max_seconds
#   Maximum number of seconds this bootstrap script is allowed to run.
#   Script will abort if it does not complete within this allotted time.
#
# @param reboot_on_failure
#   Whether to reboot the server if runpuppet fails to bootstrap the
#   client.  This allows the client to attempt fix its bootstrap problem
#   without manual intervention.  However, for sites containing a large
#   number of clients, the repeated cycle of <multiple puppet agent
#   attempts + reboot> may overtax the Puppet server.  In this case,
#   disabling this feature may be most appropriate.
#
# @param set_static_hostname
#   Whether to persist the hostname retrieved by DHCP as a static
#   hostname.  This prevents problems that can arise when the DHCP
#   lease expires in the middle of bootstrap puppet runs.  Is not
#   applicable for RedHat/CentOS 6.
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
  Stdlib::Absolutepath        $location                = '/var/www/ks/runpuppet',
  Boolean                     $set_static_hostname     = true,
  Boolean                     $reboot_on_failure       = true,
  Boolean                     $runpuppet_print_stats   = true,
  Variant[Integer[0],Boolean] $runpuppet_wait_for_cert = 10,
  Integer[1]                  $num_puppet_runs         = 2,
  Integer[1]                  $initial_retry_interval  = 10,
  Float[0.1]                  $retry_factor            = 1.5,
  Integer[1]                  $max_seconds             = 1800,
  String                      $puppet_digest_algorithm = 'sha256',
  Optional[Integer[2048]]     $puppet_keylength        = undef,
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

  if $puppet_keylength {
    $_puppet_keylength = $puppet_keylength
  } elsif $fips {
    $_puppet_keylength = 2048
  } else {
    $_puppet_keylength = 4096
  }


  # This is the bootstrap helper script used by both the systemd and systemv
  # versions of runpuppet.
  $_dir = dirname($location)
  file { "${_dir}/bootstrap_simp_client":
    ensure  => 'file',
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    content => file("${module_name}/var/www/ks/bootstrap_simp_client")
  }

  if member($facts['init_systems'], 'systemd') {
    $_template = "${module_name}/www/ks/runpuppet_systemd.erb"
  } else {
    $_template = "${module_name}/www/ks/runpuppet.erb"
  }

  file { $location:
    ensure  => 'file',
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    content => template($_template)
  }
}
