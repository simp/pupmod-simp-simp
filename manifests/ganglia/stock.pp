# Includes a stock configuration for gmond, gmetad, and gweb
#
# Note: To be able to access the web front-end, you will still need to
# make calls to ganglia::web::add_user for each user you want to create.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::ganglia::stock {
  include 'simp::ganglia::monitor'
  include 'simp::ganglia::meta'
  include 'simp::ganglia::web'
}
