require 'spec_helper_acceptance'

test_name 'simp::server::kickstart'

describe 'simp::server::kickstart' do
  let(:manifest) do
    <<~EOS
      class{ 'simp::server::kickstart':
        manage_dhcp                  => false,
        manage_tftpboot              => false,
        manage_simp_client_bootstrap => true,
        sslverifyclient              => none,
      }
    EOS
  end

  let(:hieradata) do
    <<~EOM
      ---
      simp::server::kickstart::simp_client_bootstrap::fips: #{ENV['BEAKER_fips'] == 'yes'}
      simp::server::kickstart::simp_client_bootstrap::ntp_servers: []
      simp::server::kickstart::simp_client_bootstrap::puppet_server: 'puppet.test.test'
      simp::server::kickstart::simp_client_bootstrap::puppet_ca: 'puppetca.test.test'
      simp::server::kickstart::simp_client_bootstrap::puppet_ca_port: 8140
      simp_apache::ssl: false
      simp_apache::rsync_web_root: false
      simp_apache::conf::allowroot:
        - '127.0.0.1'
        - '::1'
        - 'ALLOW_IP'

    EOM
  end

  context 'on a non-simp test host' do
    it 'disables firewall' do
      # This test is not managing the firewall and firewalld may be running
      # by default on some hosts (e.g., generic/oracle* boxes) and blocking
      # port 80.
      on(hosts, 'puppet resource service firewalld ensure=stopped')
    end

    it 'provides correctly-configured bootstrap files over HTTP' do
      server = only_host_with_role(hosts, 'server')
      client = only_host_with_role(hosts, 'client')

      on client, 'puppet resource package curl ensure=present'

      set_hieradata_on(server, hieradata.gsub('ALLOW_IP', client.ip))
      apply_manifest_on server, manifest

      on client, "curl http://#{server.ip}/ks/simp_client_bootstrap.service -f | grep 'puppet-server puppet\.test\.test'"
      on client, "curl http://#{server.ip}/ks/simp_client_bootstrap -f | grep 'puppet-server puppet\.test\.test'"
      on client, "curl http://#{server.ip}/ks/bootstrap_simp_client -f | grep '^class BootstrapSimpClient'"
    end
  end
end
