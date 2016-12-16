# Creates a stock configuration for gmetad
#
# Note: This currently only adds data from the localhost.
# You probably want to add additional at least one additional data source
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::ganglia::meta {
  include 'ganglia::meta'

  include 'ganglia::meta::conf'

  ganglia::meta::add_data_source { 'local_data':
    data_source_id => 'Local Data',
    machines       => ['localhost']
  }
}
