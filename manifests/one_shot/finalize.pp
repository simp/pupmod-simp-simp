# NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# A 'last effort' script to clean up all of the SIMP material on the system
# that may cause issues
#
# @param dry_run
#   Run the finalization script in 'dry_run' mode and output all commands
#
# @param remove_pki
#   Remove the SIMP installed host PKI certificates
#
# @param remove_puppet
#   Remove the 'puppet' package from the system
#
# @param remove_script
#   Remove the finalization script itself from the system
#
class simp::one_shot::finalize (
  Boolean $dry_run       = $simp::one_shot::finalize_dry_run,
  Boolean $remove_pki    = $simp::one_shot::finalize_remove_pki,
  Boolean $remove_puppet = $simp::one_shot::finalize_remove_puppet,
  Boolean $remove_script = $simp::one_shot::finalize_remove_script
){
  assert_private()

  $_finalize_script_name = 'simp_one_shot_finalize.sh'
  $_finalize_script = "/usr/local/sbin/${_finalize_script_name}"

  file { $_finalize_script:
    mode    => '0750',
    content => file("${module_name}/scenarios/one_shot/${_finalize_script_name}"),
  }

  # Run this in the background so that we don't break the current Puppet run
  exec { 'one_shot finalize':
    command   => "nohup ${_finalize_script} -d ${dry_run} -k ${remove_pki} -p ${remove_puppet} -f ${remove_script} > /dev/null 2>&1 &",
    logoutput => true,
    provider  => 'shell',
    require   => File[$_finalize_script]
  }
}
