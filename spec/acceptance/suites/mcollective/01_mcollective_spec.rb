require 'spec_helper_acceptance'

test_name 'simp::mcollective class'

describe 'simp::mcollective class' do
  before(:context) do
    hosts.each do |host|
      interfaces = fact_on(host, 'interfaces').strip.split(',')
      interfaces.delete_if do |x|
        x =~ /^lo/
      end

      interfaces.each do |iface|
        if fact_on(host, "ipaddress_#{iface}").strip.empty?
          on(host, "ifup #{iface}", :accept_all_exit_codes => true)
        end
      end
    end
  end

  let(:servers){ hosts_with_role( hosts, 'mco_server' ) }
  let(:clients){ hosts_with_role( hosts, 'mco_client' ) }

  activemq_test_username = 'mco_test_user'
  activemq_test_password = 'this is a bit of a long password really!'

  ssh_allow = <<-EOM
    include '::tcpwrappers'
    include '::iptables'

    tcpwrappers::allow { 'sshd':
      pattern =>  'ALL'
    }

    iptables::listen::tcp_stateful { 'i_love_testing':
      order        => 8,
      trusted_nets => ['ALL'],
      dports       => 22
    }

    pam::access::rule { 'vagrant':
      users    => ['vagrant'],
      origins  => ['ALL']
    }
  EOM

  let(:server_manifest) {
    <<-EOS
      include '::iptables'
      include '::pam::access'
      include '::simp::mcollective'

      mcollective::actionpolicy { 'service':
        default => 'deny'
      }

      mcollective::actionpolicy::rule { 'mco_user_service_status':
        agent     => 'service',
        callerid  => '*',
        action    => 'allow',
        actions   => 'status'
      }

      #{ssh_allow}
    EOS
  }

  let(:client_manifest) {
    <<-EOS
      include '::simp::mcollective'

      #{ssh_allow}
    EOS
  }

  let(:server_hieradata) {
    <<-EOS
---
simp_options::trusted_nets:
  - 'ALL'

simp_options::firewall: true

pki_dir : '/etc/pki/simp-testing/pki'
pki::private_key_source : "file://%{hiera('pki_dir')}/private/%{::fqdn}.pem"
pki::public_key_source : "file://%{hiera('pki_dir')}/public/%{::fqdn}.pub"
pki::cacerts_sources :
  - "file://%{hiera('pki_dir')}/cacerts"

simp::mcollective::mco_client : true
simp::mcollective::activemq_user: '#{activemq_test_username}'
simp::mcollective::activemq_password : '#{activemq_test_password}'
simp::mcollective::activemq_brokers :
  - #{fact_on(servers.first,'fqdn')}

# This is only needed for testing
mcollective::ssl_client_certs : '/var/mcollective_certs'
    EOS
  }

  let(:client_hieradata) {
    <<-EOS
---
simp::mcollective::mco_client : true
simp::mcollective::mco_server : false
simp::mcollective::activemq_brokers :
  - #{fact_on(servers.first,'fqdn')}
    EOS
  }

  context 'default parameters' do

    it 'should configure the mco servers with no errors' do
      servers.each do |node|

        # This just lets us stub out the regular empty directory cert source
        node.mkdir_p('/var/mcollective_certs')

        # Make sure we have the correct values in place for the Puppet config
        # that SIMP expects
        on(node, 'puppet config set stringify_facts false')
        on(node, 'puppet config set digest_algorithm sha256')

        # Set up base modules and hieradata
        set_hieradata_on( node, server_hieradata )

        # Set up an mcollective server, client, and middleware on the Server
        apply_manifest_on( node, server_manifest, :catch_failures => true)

        on node, "service mcollective status", :acceptable_exit_codes => [0]
        on node, "service activemq status", :acceptable_exit_codes => [0]
      end
    end

    it 'should configure the mco clients with no errors' do
      clients.each do |node|
        set_hieradata_on( node, client_hieradata )
        apply_manifest_on( node, client_manifest, :catch_failures => true)
      end
    end

    it 'needs to replicate keydist and distribute mcollective keys' do
      rsa_key = OpenSSL::PKey::RSA.new 2048
      private_key = rsa_key.to_pem
      public_key = rsa_key.public_key.to_pem
      servers.each{ |node|
        on node, "cat <<EOF > /etc/mcollective/ssl/mco_autokeys/mco_private.pem \n#{private_key}\nEOF"
        on node, "cat <<EOF > /etc/mcollective/ssl/mco_autokeys/mco_public.pem \n#{public_key}\nEOF"
      }
    end

    it 'should set up an mco user and certs' do
      clients.each do |node|
        on node, "adduser mco_user"
        on node, 'sed -i "1s/^/+\ :\ mco_user\ :\ LOCAL\n/" /etc/security/access.conf'
        # This is super insecure and should never be done outside of a testing environment.
        on node, "cp /etc/pki/simp-testing/pki/public/* /home/mco_user/mco_user_cert.pub"
        on node, "cp /etc/pki/simp-testing/pki/private/* /home/mco_user/mco_user_key.pem"
        on node, "openssl rsa -in /home/mco_user/mco_user_key.pem -pubout > /home/mco_user/mco_user_cert_rsa_#{node}.pem"
        on node, "chmod 644 /etc/pki/simp-testing/pki/cacerts/cacerts.pem"
        on node, "chown mco_user /home/mco_user/*"

        Dir.mktmpdir { |dir|
          scp_from(node, "/home/mco_user/mco_user_cert_rsa_#{node}.pem", dir)
          servers.each do |server|
            scp_to(server, "#{dir}/mco_user_cert_rsa_#{node}.pem", "/etc/mcollective/ssl/clients/")
          end
        }

        on node, "cat <<EOF > /home/mco_user/.mcollective
collectives = mcollective
connector = activemq
direct_addressing = 1
libdir = /usr/local/libexec/mcollective:/usr/libexec/mcollective
logger_type = console
loglevel = warn
main_collective = mcollective
plugin.activemq.base64 = yes
plugin.activemq.randomize = true
plugin.activemq.pool.1.host = #{fact_on(servers.first, 'fqdn')}
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.user = #{activemq_test_username}
plugin.activemq.pool.1.password = #{activemq_test_password}
plugin.activemq.pool.1.ssl = 1
plugin.activemq.pool.1.ssl.ca = /etc/pki/simp-testing/pki/cacerts/cacerts.pem
plugin.activemq.pool.1.ssl.cert = /home/mco_user/mco_user_cert.pub
plugin.activemq.pool.1.ssl.key = /home/mco_user/mco_user_key.pem
plugin.activemq.pool.1.ssl.fallback = 0
plugin.activemq.pool.size = 1
plugin.ssl_client_private = /home/mco_user/mco_user_key.pem
plugin.ssl_client_public = /home/mco_user/mco_user_cert_rsa_#{node}.pem
plugin.ssl_server_public = /home/mco_user/mco_public.pem
securityprovider = ssl
EOF"
        servers.each do |server|
          Dir.mktmpdir { |dir|
            scp_from(server, '/etc/mcollective/ssl/mco_autokeys/mco_public.pem', dir)
            scp_to(node, "#{dir}/mco_public.pem", "/home/mco_user")
            on(node, 'chown mco_user /home/mco_user/mco_public.pem')
          }
        end
      end
    end

    it 'should successfully mco ping' do
      clients.each do |node|
        result = on node, "runuser -l mco_user -c 'mco ping'", :acceptable_exit_codes => [0]
        servers.each do |server|
          expect(result.stdout).to include("#{server}")
        end
      end
    end

    it 'should successfully apply action policy' do
      # The mco_user should be able to query mcollective status on the server and client.
      clients.each do |node|
        result = on node, "runuser -l mco_user -c 'mco service status mcollective'", :acceptable_exit_codes => [0]
        servers.each do |server|
          expect(result.stdout).to match(/#{server}.*running/)
        end
      end

      # The mco_user should not be able to 'start' the mcollective service on the server or client.
      clients.each do |node|
        result = on node, "runuser -l mco_user -c 'yes Y | mco service start mcollective'", :acceptable_exit_codes => [2]
        servers.each do |server|
          expect(result.stdout).to match(/#{server}.*You are not authorized to call this agent or action/)
        end
      end

      # After removing the service allow policy on the client, the mco_user should no longer
      # be able to query the status of mcollective on the client.  The server should still
      # return status.
      on servers.first, "echo 'policy default deny' > /etc/mcollective/policies/service.policy"
      result = on clients.first, "runuser -l mco_user -c 'mco service status mcollective -I #{fact_on(servers.first,'fqdn')}'", :acceptable_exit_codes => [2]
      expect(result.stdout).to match(/You are not authorized to call this agent or action/)

      result = on clients.first, "runuser -l mco_user -c 'mco service status mcollective -I #{fact_on(servers.last, 'fqdn')}'", :acceptable_exit_codes => [0]
      expect(result.stdout).to match(/#{servers.last}.*running/)
    end
  end
end
