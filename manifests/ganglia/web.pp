# Creates a stock configuration for gmond, gmetad, and ganglia-web
#
# Note: In order to access the web front-end, you will need to
# add users via ganglia::web::add_user.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::ganglia::web {
  include 'ganglia::web'

  include 'ganglia::web::conf'
  include 'ganglia::web::configure_php'

  file { '/usr/local/apache':
    ensure => 'directory',
    owner  => 'root',
    group  => 'apache',
    mode   => '0750'
  }
}
