require 'spec_helper_acceptance'

test_name 'simp::netconsole class'

describe 'simp::netconsole class' do
  shipper = only_host_with_role(hosts, 'shipper')
  receiver = only_host_with_role(hosts, 'receiver')
  receiver_ip  = fact_on(receiver, 'ipaddress_eth1')
  receiver_mac = fact_on(receiver, 'macaddress_eth1')

  context 'should send logs' do
    let(:manifest) do
      <<~EOS
        class { 'simp::netconsole':
          ensure         => present,
          source_device  => 'eth1',
          source_port    => 6665,
          target_port    => 514,
          target_ip      => "#{receiver_ip}",
          target_macaddr => "#{receiver_mac}",
        }
        # I need the kernel to be a little louder than normal when booting
        kernel_parameter { 'quiet':    ensure => absent  }
        kernel_parameter { 'debug':    ensure => present }
        kernel_parameter { 'loglevel': ensure => present, value => '7' }
      EOS
    end

    let(:remove_manifest) { "class { 'simp::netconsole': ensure => absent }" }

    it 'disables the firewall' do
      # This test is not managing rsyslog, so the incoming rsyslog port may not be
      # allowed when the firewall is enabled (e.g., on generic/oracle* boxes).
      on(hosts, 'puppet resource service firewalld ensure=stopped')
    end

    it 'configures hosts to listen for udp logs' do
      create_remote_file(hosts, '/etc/rsyslog.d/udp.conf', <<-EOF
          $ModLoad imudp
          $UDPServerRun 514
        EOF
      )
      on(hosts, 'systemctl restart rsyslog')
    end

    it "configures the shipper (#{shipper.name})" do
      apply_manifest_on(shipper, manifest, catch_failures: true)
      apply_manifest_on(shipper, manifest, catch_changes: true)
    end

    it 'has a properly configured netconsole' do
      result = on(shipper, 'cat /etc/sysconfig/netconsole')
      expect(result.stdout).to include "SYSLOGADDR=#{receiver_ip}"
      expect(result.stdout).to include 'LOCALPORT=6665'
      expect(result.stdout).to include 'DEV=eth1'
      expect(result.stdout).to include 'SYSLOGPORT=514'
      expect(result.stdout).to include "SYSLOGMACADDR=#{receiver_mac}"
    end

    it "reboots the shipper (#{shipper.name}) and send logs to the receiver" do
      sleep 20
      shipper.reboot
      retry_on(shipper, 'ls')
      sleep 20

      result = on(receiver, "grep #{shipper.name} /var/log/messages")
      expect(result.stdout).to include('netconsole: network logging started')
    end

    it "unconfigures the shipper (#{shipper.name})" do
      apply_manifest_on(shipper, remove_manifest, catch_failures: true)
    end
  end
end
