# Configure the ec2-user in AWS to avoid lockout
#
class simp::cloud::amazon {
  file { '/etc/ssh/local_keys/ec2-user':
    ensure => present,
    owner  => 'ec2-user',
    group  => 'ec2-user',
    mode   => '0600',
    source => '/home/ec2-user/.ssh/authorized_keys'
  }

  pam::access::rule { 'ec2-user':
    permission => '+',
    users      => ['ec2-user'],
    origins    => ['ALL'],
    order      => 1000
  }

  sudo::user_specification { 'ec2-user':
    user_list => ['ec2-user'],
    passwd    => false,
    host_list => [$facts['ec2_metadata']['hostname']],
    runas     => 'root',
    cmnd      => ['/bin/su root', '/bin/su - root', '/bin/sudo', '/usr/bin/sudo']
  }
}
