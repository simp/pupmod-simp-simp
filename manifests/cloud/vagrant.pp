# Configure the vagrant user to avoid lockout
#
class simp::cloud::vagrant {
  file { '/etc/ssh/local_keys/vagrant':
    ensure => present,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0600',
    source => '/home/vagrant/.ssh/authorized_keys',
  }

  pam::access::rule { 'vagrant':
    permission => '+',
    users      => ['vagrant'],
    origins    => ['ALL'],
    order      => 1000,
  }

  sudo::user_specification { 'vagrant':
    user_list => ['vagrant'],
    passwd    => false,
    runas     => 'root',
    cmnd      => ['ALL'],
  }
}
