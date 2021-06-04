require 'spec_helper_acceptance'
require 'erb'

test_name 'remote_access scenario'

# SIMP remote_access scenario acceptance
#
# The remote_access scenario includes the components required for
# for a user to 'log into' a client (and nothing more!).  The test
# procedure is as follows:
#   1. Create an ldap server on a server node
#   2. Add an LDAP 'testuser'
#   3. Apply the remote_access scenario on client nodes.
#   4. Attempt to ssh as 'testuser' to the client nodes.

describe 'remote_access scenario' do
  let(:plain_server_manifest) {
    <<-EOS
      include 'simp_openldap::server'
    EOS
  }
  let(:ds389_server_manifest) {
    <<-EOS
      include 'simp_ds389::instances::accounts'
    EOS
  }
  let(:client_manifest) {
    <<-EOS
      include 'simp_options'
      include 'simp'
    EOS
  }
  let(:root_pw) { 'suP3rP@ssw0r!'}


  ldap_servers = hosts_with_role(hosts, 'ldap_server')
  clients = hosts_with_role(hosts, 'client')

  # Both client and server need these
  ldap_servers.each do |ldap_server|

    context 'Test running on current LDAP server #{ldap_server}' do
      let(:server_fqdn) { fact_on(ldap_server, 'fqdn') }
      let(:base_dn) { fact_on(ldap_server, 'domain').split('.').map{ |d| "dc=#{d}" }.join(',') }
      # For now default to openldap server until test includes a 389DS server
      let(:ldap_type) {
        if fact_on(ldap_server,'operatingsystemmajrelease') == '7'
          'plain'
        else
          '389ds'
        end
      }
      let(:common_hieradata)      { File.read(File.expand_path('templates/common_hieradata.yaml.erb', File.dirname(__FILE__))) }
      let(:server_hieradata)      { File.read(File.expand_path("templates/#{ldap_type}/server_hieradata.yaml.erb", File.dirname(__FILE__))) }
      let(:hieradata)             { "#{common_hieradata}" + "\n#{server_hieradata}" }
      let(:add_testuser)          { File.read(File.expand_path("templates/#{ldap_type}/add_testuser.erb", File.dirname(__FILE__))) }
      let(:root_pw)               { 'suP3rP@ssw0r!' }
      # The instance name from simp_ds389
      let(:ds_root_name)          { 'accounts' }
      let(:test_user) { 'test.user' }


      it 'should configure hiera' do
         set_hieradata_on(ldap_server, ERB.new(hieradata).result(binding))
      end

      if fact_on(ldap_server,'operatingsystemmajrelease') == '7'
        context 'on el7 install openldap server and create users' do
          let(:add_testuser_to_admin) { File.read(File.expand_path("templates/#{ldap_type}/add_testuser_to_admin.erb", File.dirname(__FILE__))) }

          # Needed for ppassword policy
          it 'should set up needed repositories' do
            on(ldap_server, 'yum -y install https://download.simp-project.com/simp-release-community.rpm')
          end

          it 'should set up an openldap ldap server' do
            apply_manifest_on(ldap_server, plain_server_manifest, :catch_failures => true)
            apply_manifest_on(ldap_server, plain_server_manifest, :acceptable_exit_codes => [0,2])
          end
          it 'should be able to connect and use ldapsearch' do
            on(ldap_server, "ldapsearch -Z -LLL -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w #{root_pw}")
          end
          it 'should be able to add a user' do
            create_remote_file(ldap_server, '/tmp/add_testuser.ldif', ERB.new(add_testuser).result(binding))

            on(ldap_server, "ldapadd -Z -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w #{root_pw} -x -f /tmp/add_testuser.ldif")

            result = on(ldap_server, "ldapsearch -Z -LLL -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w #{root_pw} -x uid=#{test_user}")
            expect(result.stdout).to include("dn: uid=#{test_user},ou=People,#{base_dn}")
          end
          it 'should be able to add user to group' do
            create_remote_file(ldap_server, '/tmp/add_testuser_to_admin.ldif', ERB.new(add_testuser_to_admin).result(binding))

            on(ldap_server, "ldapmodify -Z -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w #{root_pw} -x -f /tmp/add_testuser_to_admin.ldif")

            result = on(ldap_server, "ldapsearch -Z -LLL -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w #{root_pw} -x cn=#{test_user}")
            expect(result.stdout).to include("dn: cn=#{test_user},ou=Group,#{base_dn}")
          end
        end
      else
        context 'on versions later than el7 install 389ds and create users' do
          it 'should install 389ds with simp_ds389' do
            apply_manifest_on(ldap_server, ds389_server_manifest, :catch_failures => true)
            apply_manifest_on(ldap_server, ds389_server_manifest, :acceptable_exit_codes => [0,2])
          end
          it 'should add the test user' do
            create_remote_file(ldap_server, '/root/ldap_add_user',ERB.new(add_testuser).result(binding))
            on(ldap_server, 'chmod +x /root/ldap_add_user')
            on(ldap_server, '/root/ldap_add_user')
            result = on(ldap_server, "dsidm #{ds_root_name} -b #{base_dn} user list")
            expect(result.stdout).to include("#{test_user}")
          end
        end
      end # If el7


      # Copy in the password-less key
      it 'should copy the testuser private key' do
        scp_to(ldap_server, './spec/acceptance/suites/scenario_remote_access/files/id_rsa.example', '/tmp/testkey')
        on(ldap_server, 'chmod 600 /tmp/testkey')
      end

      clients.each do |client|
        context "set up remote_access scenario on #{client}" do
          let(:common_hieradata)      { File.read(File.expand_path('templates/common_hieradata.yaml.erb', File.dirname(__FILE__))) }
          let(:client_hieradata)      { File.read(File.expand_path('templates/client_hieradata.yaml.erb', File.dirname(__FILE__))) }
          let(:cc_hieradata)          { "#{common_hieradata}" + "\n#{client_hieradata}" }
          let(:client_fqdn) { fact_on(client, 'fqdn') }

          # FIXME: SIMP-9136
          #  Still needed for tlog on el7.
          if fact_on(ldap_server,'operatingsystemmajrelease') == '7'
            it 'should set up needed repositories' do
              on(client, 'yum -y install https://download.simp-project.com/simp-release-community.rpm')
            end
          end

          it 'should configure hiera' do
            set_hieradata_on(client, ERB.new(cc_hieradata).result(binding))
          end
          it 'should apply the remote_access scenario without error' do
            apply_manifest_on(client, client_manifest, :catch_failures => true)
            apply_manifest_on(client, client_manifest, :catch_failures => true)
          end
          it 'should id testuser' do
            result = on(client, "id #{test_user}", :acceptable_exit_codes => [0])
            expect(result.stdout).to include("uid=10000(#{test_user})")
          end
          it 'should ssh from *server* to client' do
            on(ldap_server, "ssh -o StrictHostKeyChecking=no -i /tmp/testkey #{test_user}@#{client} echo Logged in successfully")
          end
        end
      end # End client loop

    end  # End the LDAP Server Context
  end  # End server loop
end
