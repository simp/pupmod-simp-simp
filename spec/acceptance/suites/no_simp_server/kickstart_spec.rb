require 'spec_helper_acceptance'

test_name 'simp::server::kickstart::runpuppet'

host_pairs = [{ :server => 'server-el7',  :client => 'server-el6' },
              { :server => 'server-el6',  :client => 'server-el7' }]

describe 'simp::server::kickstart::runpuppet' do
  let(:manifest) {
    <<-EOS
      class{ 'simp::server::kickstart':
        manage_dhcp      => false,
        manage_tftpboot  => false,
        manage_runpuppet => true,
        sslverifyclient  => none,
      }
    EOS
  }

  let(:hieradata) {
    <<-EOM
---
simp::server::kickstart::runpuppet::fips: #{(ENV['BEAKER_fips'] == 'yes').to_s}
simp::server::kickstart::runpuppet::ntp_servers: []
simp::server::kickstart::runpuppet::puppet_server: 'puppet.test.test'
simp::server::kickstart::runpuppet::puppet_ca: 'puppetca.test.test'
simp::server::kickstart::runpuppet::puppet_ca_port: 8140
simp_apache::ssl: false
simp_apache::rsync_web_root: false
simp_apache::conf::allowroot:
  - '127.0.0.1'
  - '::1'
  - 'ALLOW_IP'

    EOM
  }
  context 'on a non-simp test host' do
    # Using puppet_apply as a helper
    it 'should provide a correctly-configured `runpuppet` file over HTTP' do

      hosts.each do |host|
          _clients=(hosts-[host])
          skip('There are no remote hosts to act as clients') if _clients.size == 0
          client = _clients.first
          on client, 'puppet resource package curl ensure=present'
          set_hieradata_on(host, hieradata.gsub('ALLOW_IP',client.ip))
          apply_manifest_on host, manifest
          on client, "curl http://server-el7/ks/runpuppet -f | grep '^ *server *= *puppet\.test\.test'"
      end
    end
  end
end

