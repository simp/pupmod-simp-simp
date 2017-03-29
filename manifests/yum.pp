# Set up the ``/etc/yum`` directory, enable an auto-update cron-job
#
# @param auto_update
#   Enable the automatic yum cron job
#
class simp::yum (
  Boolean $auto_update = true,
){
  file { [
    '/etc/yum',
    '/etc/yum.repos.d'
  ]:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    recurse => true
  }

  if $auto_update {
    include '::simp::yum::schedule'
  }
  else {
    class {'simp::yum::schedule': enable => $auto_update}
  }
}
