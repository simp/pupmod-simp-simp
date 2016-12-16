# Includes a stock configuration for gmond
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp::ganglia::monitor {
  include 'ganglia::monitor'

  include 'ganglia::monitor::globals'
  include 'ganglia::monitor::cluster'
  include 'ganglia::monitor::host'
  ganglia::monitor::udp_send_channel { 'default':
    udp_send_mcast_join => '239.2.11.71',
    udp_send_port       => '8649',
    udp_send_ttl        => '1'
  }

  ganglia::monitor::udp_recv_channel::conf { 'default':
    udp_recv_mcast_join => '239.2.11.71',
    udp_recv_port       => '8649',
    udp_recv_bind       => '239.2.11.71'
  }
  ganglia::monitor::udp_recv_channel::add_acl_access { 'localhost':
    udp_recv_name => 'default',
    udp_recv_port => '8649',
    access_ip     => '127.0.0.1',
    access_mask   => '32',
    access_action => 'allow'
  }

  ganglia::monitor::tcp_accept_channel::conf { 'default':
    tcp_accept_port => '8649'
  }
  ganglia::monitor::tcp_accept_channel::add_acl_access { 'localhost':
    tcp_accept_name => 'default',
    tcp_accept_port => '8649',
    access_ip       => '127.0.0.1',
    access_mask     => '32',
    access_action   => 'allow'
  }

  ganglia::monitor::mods::add_module{ 'core_metrics': }

  ganglia::monitor::mods::add_module{ 'cpu_module':
    mod_path => 'modcpu.so'
  }
  ganglia::monitor::mods::add_module{ 'disk_module':
    mod_path => 'moddisk.so'
  }
  ganglia::monitor::mods::add_module{ 'load_module':
    mod_path => 'modload.so'
  }
  ganglia::monitor::mods::add_module{ 'mem_module':
    mod_path => 'modmem.so'
  }
  ganglia::monitor::mods::add_module{ 'net_module':
    mod_path => 'modnet.so'
  }
  ganglia::monitor::mods::add_module{ 'proc_module':
    mod_path => 'modproc.so'
  }
  ganglia::monitor::mods::add_module{ 'sys_module':
    mod_path => 'modsys.so'
  }

#  ganglia::monitor::add_includes { 'default':
#    includes => [ '/etc/ganglia/conf.d/*.conf' ]
#  }
  include 'ganglia::monitor::add_includes'

  ganglia::monitor::collection_group::conf { 'heartbeat':
    collect_once           => 'yes',
    collect_time_threshold => '20'
  }
  ganglia::monitor::collection_group::add_metric { 'heartbeat':
    collection_group_name => 'heartbeat'
  }

  ganglia::monitor::collection_group::conf { 'general':
    collect_once           => 'yes',
    collect_time_threshold => '1200'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_num':
    collection_group_name => 'general',
    metric_title          => 'CPU Count'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_speed':
    collection_group_name => 'general',
    metric_title          => 'CPU Speed'
  }
  ganglia::monitor::collection_group::add_metric { 'mem_total':
    collection_group_name => 'general',
    metric_title          => 'Memory Total'
  }
  ganglia::monitor::collection_group::add_metric { 'swap_total':
    collection_group_name => 'general',
    metric_title          => 'Swap Space Total'
  }
  ganglia::monitor::collection_group::add_metric { 'boottime':
    collection_group_name => 'general',
    metric_title          => 'Last Boot Time'
  }
  ganglia::monitor::collection_group::add_metric { 'machine_type':
    collection_group_name => 'general',
    metric_title          => 'Machine Type'
  }
  ganglia::monitor::collection_group::add_metric { 'os_name':
    collection_group_name => 'general',
    metric_title          => 'Operating System'
  }
  ganglia::monitor::collection_group::add_metric { 'os_release':
    collection_group_name => 'general',
    metric_title          => 'Operating System Release'
  }
  ganglia::monitor::collection_group::add_metric { 'location':
    collection_group_name => 'general',
    metric_title          => 'Location'
  }

  ganglia::monitor::collection_group::conf { 'gexecd':
    collect_once           => 'yes',
    collect_time_threshold => '300'
  }
  ganglia::monitor::collection_group::add_metric { 'gexec':
    collection_group_name => 'gexecd',
    metric_title          => 'Gexec Status'
  }

  ganglia::monitor::collection_group::conf { 'cpu':
    collect_every          => '20',
    collect_time_threshold => '90'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_user':
    collection_group_name  => 'cpu',
    metric_value_threshold => '1.0',
    metric_title           => 'CPU User'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_system':
    collection_group_name  => 'cpu',
    metric_value_threshold => '1.0',
    metric_title           => 'CPU System'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_idle':
    collection_group_name  => 'cpu',
    metric_value_threshold => '5.0',
    metric_title           => 'CPU Idle'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_nice':
    collection_group_name  => 'cpu',
    metric_value_threshold => '1.0',
    metric_title           => 'CPU Nice'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_aidle':
    collection_group_name  => 'cpu',
    metric_value_threshold => '5.0',
    metric_title           => 'CPU aidle'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_wio':
    collection_group_name  => 'cpu',
    metric_value_threshold => '1.0',
    metric_title           => 'CPU wio'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_intr':
    collection_group_name  => 'cpu',
    metric_value_threshold => '1.0',
    metric_title           => 'CPU intr'
  }
  ganglia::monitor::collection_group::add_metric { 'cpu_sintr':
    collection_group_name  => 'cpu',
    metric_value_threshold => '1.0',
    metric_title           => 'CPU sintr'
  }

  ganglia::monitor::collection_group::conf { 'load':
    collect_every          => '20',
    collect_time_threshold => '90'
  }
  ganglia::monitor::collection_group::add_metric { 'load_one':
    collection_group_name  => 'load',
    metric_value_threshold => '1.0',
    metric_title           => 'One Minute Load Average'
  }
  ganglia::monitor::collection_group::add_metric { 'load_five':
    collection_group_name  => 'load',
    metric_value_threshold => '1.0',
    metric_title           => 'Five Minute Load Average'
  }
  ganglia::monitor::collection_group::add_metric { 'load_fifteen':
    collection_group_name  => 'load',
    metric_value_threshold => '1.0',
    metric_title           => 'Fifteen Minute Load Average'
  }

  ganglia::monitor::collection_group::conf { 'proc':
    collect_every          => '80',
    collect_time_threshold => '950'
  }
  ganglia::monitor::collection_group::add_metric { 'proc_run':
    collection_group_name  => 'proc',
    metric_value_threshold => '1.0',
    metric_title           => 'Total Running Processes'
  }
  ganglia::monitor::collection_group::add_metric { 'proc_total':
    collection_group_name  => 'proc',
    metric_value_threshold => '1.0',
    metric_title           => 'Total Processes'
  }

  ganglia::monitor::collection_group::conf { 'mem':
    collect_every          => '40',
    collect_time_threshold => '180'
  }
  ganglia::monitor::collection_group::add_metric { 'mem_free':
    collection_group_name  => 'mem',
    metric_value_threshold => '1024',
    metric_title           => 'Free Memory'
  }
  ganglia::monitor::collection_group::add_metric { 'mem_shared':
    collection_group_name  => 'mem',
    metric_value_threshold => '1024',
    metric_title           => 'Shared Memory'
  }
  ganglia::monitor::collection_group::add_metric { 'mem_buffers':
    collection_group_name  => 'mem',
    metric_value_threshold => '1024',
    metric_title           => 'Memory Buffers'
  }
  ganglia::monitor::collection_group::add_metric { 'mem_cached':
    collection_group_name  => 'mem',
    metric_value_threshold => '1024',
    metric_title           => 'Cached Memory'
  }
  ganglia::monitor::collection_group::add_metric { 'swap_free':
    collection_group_name  => 'mem',
    metric_value_threshold => '1024',
    metric_title           => 'Free Swap Space'
  }

  ganglia::monitor::collection_group::conf { 'net':
    collect_every          => '40',
    collect_time_threshold => '300'
  }
  ganglia::monitor::collection_group::add_metric { 'bytes_out':
    collection_group_name  => 'net',
    metric_value_threshold => '4096',
    metric_title           => 'Bytes Sent'
  }
  ganglia::monitor::collection_group::add_metric { 'bytes_in':
    collection_group_name  => 'net',
    metric_value_threshold => '4096',
    metric_title           => 'Bytes Received'
  }
  ganglia::monitor::collection_group::add_metric { 'pkts_in':
    collection_group_name  => 'net',
    metric_value_threshold => '256',
    metric_title           => 'Packets Received'
  }
  ganglia::monitor::collection_group::add_metric { 'pkts_out':
    collection_group_name  => 'net',
    metric_value_threshold => '256',
    metric_title           => 'Packets Sent'
  }

  ganglia::monitor::collection_group::conf { 'disk_tot':
    collect_every          => '1800',
    collect_time_threshold => '3600'
  }
  ganglia::monitor::collection_group::add_metric { 'disk_total':
    collection_group_name  => 'disk_tot',
    metric_value_threshold => '1.0',
    metric_title           => 'Total Disk Space'
  }

  ganglia::monitor::collection_group::conf { 'disk':
    collect_every          => '40',
    collect_time_threshold => '180'
  }
  ganglia::monitor::collection_group::add_metric { 'disk_free':
    collection_group_name  => 'disk',
    metric_value_threshold => '1.0',
    metric_title           => 'Disk Space Available'
  }
  ganglia::monitor::collection_group::add_metric { 'part_max_used':
    collection_group_name  => 'disk',
    metric_value_threshold => '1.0',
    metric_title           => 'Maximum Disk Space Used'
  }
}
