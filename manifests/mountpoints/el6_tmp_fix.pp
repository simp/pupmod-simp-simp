# There is a bizarre bug where ``/tmp`` and ``/var/tmp`` will have incorrect
# permissions after the *second* reboot after bootstrapping SIMP. This upstart
# job is an effective, but kludgy, way to remedy this issue
#
# We have not been able to repeat the issue reliably enough in a controlled
# environment to determine the root cause.
class simp::mountpoints::el6_tmp_fix {

  simplib::assert_metadata( $module_name )

  include '::upstart'

  upstart::job { 'fix_tmp_perms':
    main_process_type => 'script',
    main_process      => '
perm1=$(/usr/bin/find /tmp -maxdepth 0 -perm -ugo+rwxt | /usr/bin/wc -l)
perm2=$(/usr/bin/find /var/tmp -maxdepth 0 -perm -ugo+rwxt | /usr/bin/wc -l)

if [ "$perm1" != "1" ]; then
/bin/chmod ugo+rwxt /tmp
fi

if [ "$perm2" != "1" ]; then
/bin/chmod ugo+rwxt /var/tmp
fi
',
    start_on          => 'runlevel [0123456]',
    description       => 'Used to enforce /tmp and /var/tmp permissions to be 777.'
  }
}
