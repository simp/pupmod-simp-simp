require 'spec_helper_acceptance'

test_name 'simp::mcollective class'

describe 'simp::mcollective class' do

  let(:server){ only_host_with_role( hosts, 'server' ) }
  let(:clients){ hosts_with_role( hosts, 'client' ) }
  let(:server_fqdn){ fact_on( server, 'fqdn' ) }
  let(:el7){ hosts_with_role( hosts, 'el7' ) }

  let(:base_manifest) {
    <<-EOS
      include 'ssh'
    EOS
  }

  let(:mcollective_manifest) {
    <<-EOS
      include 'iptables'
      include 'pam::access'
      include 'simp::mcollective'
      iptables::add_tcp_stateful_listen { 'ssh':
        dports => '22',
        client_nets => 'any'
      }
      mcollective::actionpolicy { 'service':
        default => 'deny'
      }
      mcollective::actionpolicy::rule { 'mco_user_service_status':
        agent => 'service',
        callerid => '*',
        action => 'allow',
        actions => 'status'
      }
    EOS
  }

  let(:default_hieradata) {
    <<-EOS
client_nets:
  - 'ALL'
mcollective::client : true
use_iptables: true
activemq::mq_admin_password : 'foobarbaz'
activemq::mq_cluster_password : 'foobarbaz'
simp::mcollective::keystore_password : 'foobarbaz'
simp::mcollective::truststore_password : 'foobarbaz'
mcollective::middleware_admin_password : 'foobarbaz'
mcollective::middleware_password : 'foobarbaz'
simp::mcollective::keystore_certificate : '/etc/pki/simp-testing/pki/public/%{::fqdn}.pub'
simp::mcollective::keystore_key : '/etc/pki/simp-testing/pki/private/%{::fqdn}.pem'
simp::mcollective::truststore_certificate : '/etc/pki/simp-testing/pki/cacerts/cacerts.pem'
activemq::manage_config : false
mcollective::middleware_hosts :
  - #{server_fqdn}
mcollective::server : true
mcollective::middleware : true
mcollective::securityprovider: 'ssl'
mcollective::middleware_ssl : true
mcollective::connector : 'activemq'
activemq::instance : 'mcollective'
mcollective::ssl_client_certs_dir :  '/etc/mcollective/ssl/clients'
mcollective::ssl_client_certs : '/var/mcollective_certs'
mcollective::middleware_ssl_ca_path : '/etc/mcollective/ssl/middleware_ca.pem'
mcollective::middleware_ssl_ca : '/etc/pki/simp-testing/pki/cacerts/cacerts.pem'
mcollective::ssl_mco_autokeys : true
mcollective::middleware_ssl_ca_path : '/etc/mcollective/ssl/middleware_ca.pem'
mcollective::middleware_ssl_ca_real : '/etc/pki/simp-testing/pki/cacerts/cacerts.pem'
mcollective::middleware_ssl_key : '/etc/pki/simp-testing/pki/private/%{::fqdn}.pem'
mcollective::middleware_ssl_key_path : '/etc/mcollective/ssl/middleware_key.pem'
mcollective::middleware_ssl_cert : '/etc/pki/simp-testing/pki/public/%{::fqdn}.pub'
mcollective::middleware_ssl_cert_path : '/etc/mcollective/ssl/middleware_cert.pub'
    EOS
  }

  context 'default parameters' do

    it 'should configure mco server, client, and middleware, and action policy with no errors' do
      [server, clients].flatten.each do |node|

        # This is provided by the pki rpm.  We copy fixtures, not install them.
        # It must be manually provisioned.
        on(node, 'mkdir -p /var/mcollective_certs')
        on(node, 'chmod 750 /var/mcollective_certs')
        on(node, 'chown root.puppet /var/mcollective_certs')

        # Make sure we have the correct values in place for the Puppet config
        # that SIMP expects
        on(node, 'puppet config set stringify_facts false')
        on(node, 'puppet config set digest_algorithm sha256')

        # Set up base modules and hieradata
        set_hieradata_on( node, default_hieradata, 'default' )
        apply_manifest_on( node, base_manifest, :catch_failures => false)

        # Set up an mcollective server, client, and middleware on the Server
        apply_manifest_on( node, mcollective_manifest, :catch_failures => true)

        # Tanukiwrapper is required by the init.d scripts in rhe7. Remove it.
        on el7, "rm -f /etc/init.d/activemq"

        on node, "service mcollective status", :acceptable_exit_codes => [0]
        on node, "service activemq status", :acceptable_exit_codes => [0]
      end
    end

    it 'needs to replicate keydist and distribute mcollective keys' do
      rsa_key = OpenSSL::PKey::RSA.new 2048
      private_key = rsa_key.to_pem
      public_key = rsa_key.public_key.to_pem
      [server, clients].flatten.each{ |sut|
        on sut, "cat <<EOF > /etc/mcollective/ssl/mco_autokeys/mco_private.pem \n#{private_key}\nEOF"
        on sut, "cat <<EOF > /etc/mcollective/ssl/mco_autokeys/mco_public.pem \n#{public_key}\nEOF"
      }
    end

    it 'should set up an mco user and certs' do
      clients.each do |node|

        on node, "adduser mco_user"
        on node, 'sed -i "1s/^/+\ :\ mco_user\ :\ LOCAL\n/" /etc/security/access.conf'
        on node, "cat <<EOF > /home/mco_user/.mcollective
collectives = mcollective
connector = activemq
direct_addressing = 1
libdir = /usr/local/libexec/mcollective:/usr/libexec/mcollective
logger_type = console
loglevel = warn
main_collective = mcollective
plugin.activemq.base64 = yes
plugin.activemq.pool.1.host = #{server_fqdn}
plugin.activemq.pool.1.password = foobarbaz
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.ssl = 1
plugin.activemq.pool.1.ssl.ca = /etc/pki/simp-testing/pki/cacerts/cacerts.pem
plugin.activemq.pool.1.ssl.cert = /home/mco_user/mco_user_cert.pub
plugin.activemq.pool.1.ssl.fallback = 0
plugin.activemq.pool.1.ssl.key = /home/mco_user/mco_user_key.pem
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.size = 1
plugin.activemq.randomize = true
plugin.ssl_client_private = /home/mco_user/mco_user_key.pem
plugin.ssl_client_public = /home/mco_user/mco_user_cert_rsa_#{node}.pem
plugin.ssl_server_public = /home/mco_user/mco_public.pem
securityprovider = ssl
EOF"
        # This is super insecure and should never be done outise of a testing environment.
        on node, "cp /etc/pki/simp-testing/pki/public/* /home/mco_user/mco_user_cert.pub"
        on node, "cp /etc/pki/simp-testing/pki/private/* /home/mco_user/mco_user_key.pem"
        on node, "openssl rsa -in /home/mco_user/mco_user_key.pem -pubout > /home/mco_user/mco_user_cert_rsa_#{node}.pem"
        on node, "cp /home/mco_user/mco_user_cert_rsa_#{node}.pem /etc/mcollective/ssl/clients/"
        on node, "chmod 644 /etc/pki/simp-testing/pki/cacerts/cacerts.pem"
        on node, "cp /etc/mcollective/ssl/mco_autokeys/mco_public.pem /home/mco_user/"
        on node, "chown mco_user /home/mco_user/*"
        Dir.mktmpdir { |dir|
          scp_from(node, "/home/mco_user/mco_user_cert_rsa_#{node}.pem", dir)
          scp_to(server, "#{dir}/mco_user_cert_rsa_#{node}.pem", "/etc/mcollective/ssl/clients/")
        }
      end
    end

    it 'should successfully mco ping' do
      clients.each do |node|
        result = on node, "runuser -l mco_user -c 'mco ping'", :acceptable_exit_codes => [0]
        expect(result.stdout).to include("#{server}")
        expect(result.stdout).to include("#{node}")
      end
    end

    it 'should successfully apply action policy' do
      # The mco_user should be able to query mcollective status on the server and client.
      clients.each do |node|
        result = on node, "runuser -l mco_user -c 'mco service status mcollective'", :acceptable_exit_codes => [0]
        expect(result.stdout).to match(/#{server}.*running/)
        expect(result.stdout).to match(/#{node}.*running/)
      end

      # The mco_user should not be able to 'start' the mcollective service on the server or client.
      clients.each do |node|
        result = on node, "runuser -l mco_user -c 'yes Y | mco service start mcollective'", :acceptable_exit_codes => [2]
        expect(result.stdout).to match(/#{node}.*You are not authorized to call this agent or action/)
        expect(result.stdout).to match(/#{server}.*You are not authorized to call this agent or action/)
      end

      # After removing the service allow policy on the client, the mco_user should no longer
      # be able to query the status of mcollective on the client.  The server should still
      # return status.
      clients.each do |node|
        on node, "echo 'policy default deny' > /etc/mcollective/policies/service.policy"
        result = on node, "runuser -l mco_user -c 'mco service status mcollective'", :acceptable_exit_codes => [2]
        expect(result.stdout).to match(/#{node}.*You are not authorized to call this agent or action/)
        expect(result.stdout).to match(/#{server}.*running/)
      end
    end
  end
end
