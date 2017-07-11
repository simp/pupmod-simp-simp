require 'spec_helper_acceptance'
require 'erb'

test_name 'remote_access scenario'

# SIMP remote_access scenario acceptance
#
# The remote_access scenario includes the components required for
# for a user to 'log into' a client (and nothing more!).  The test
# procedure is as follows:
#   1. Create an ldap server on server-el7
#   2. Add an LDAP 'test.user'
#   3. Apply the remote_access scenario on client-el7 and client-el6
#   4. Attempt to ssh as 'test.user' to client-el7 and client-el6.

describe 'remote_access scenario' do
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

  let(:server_manifest) {
    <<-EOS
      include 'simp_openldap::server'
    EOS
  }
  let(:client_manifest) {
    <<-EOS
      include 'simp_options'
      include 'simp'
    EOS
  }

  ldap_server = only_host_with_role(hosts, 'ldap_server')
  clients = hosts_with_role(hosts, 'client')

  # Both client and server need these
  let(:server_fqdn) { fact_on(ldap_server, 'fqdn') }
  let(:base_dn) { fact_on(ldap_server, 'domain').split('.').map{ |d| "dc=#{d}" }.join(',') }

  context "set up simp_openldap::server on #{ldap_server}" do
    let(:server_hieradata)      { File.read(File.expand_path('templates/server_hieradata.yaml.erb', File.dirname(__FILE__))) }
    let(:add_testuser)          { File.read(File.expand_path('templates/add_testuser.ldif.erb', File.dirname(__FILE__))) }
    let(:add_testuser_to_admin) { File.read(File.expand_path('templates/add_testuser_to_admin.ldif.erb', File.dirname(__FILE__))) }

    # Required for simp ldap password policy
    it 'should set up needed repositories' do
      on(ldap_server, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X_Dependencies/script.rpm.sh | bash')
    end
    it 'should configure hiera' do
       set_hieradata_on(ldap_server, ERB.new(server_hieradata).result(binding))
    end
    it 'should set up an ldap server' do
      apply_manifest_on(ldap_server, server_manifest, :catch_failures => true)
      apply_manifest_on(ldap_server, server_manifest, :acceptable_exit_codes => [0,2])
    end
    it 'should be able to connect and use ldapsearch' do
      on(ldap_server, "ldapsearch -Z -LLL -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r!")
    end
    it 'should be able to add a user' do
      create_remote_file(ldap_server, '/tmp/add_testuser.ldif', ERB.new(add_testuser).result(binding))

      on(ldap_server, "ldapadd -Z -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r! -x -f /tmp/add_testuser.ldif")

      result = on(ldap_server, "ldapsearch -Z -LLL -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r! -x uid=test.user")
      expect(result.stdout).to include("dn: uid=test.user,ou=People,#{base_dn}")
    end
    it 'should be able to add user to group' do
      create_remote_file(ldap_server, '/tmp/add_testuser_to_admin.ldif', ERB.new(add_testuser_to_admin).result(binding))

      on(ldap_server, "ldapmodify -Z -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r! -x -f /tmp/add_testuser_to_admin.ldif")

      result = on(ldap_server, "ldapsearch -Z -LLL -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r! -x cn=test.user")
      expect(result.stdout).to include("dn: cn=test.user,ou=Group,#{base_dn}")
    end
    # Copy in the password-less key
    it 'should copy the test.user private key' do
      scp_to(ldap_server, './spec/acceptance/suites/scenario_remote_access/files/id_rsa.example', '/tmp/testkey')
      on(ldap_server, 'chmod 600 /tmp/testkey')
    end
  end

  clients.each do |client|
    context "set up remote_access scenario on #{client}" do
      let(:client_hieradata)      { File.read(File.expand_path('templates/client_hieradata.yaml.erb', File.dirname(__FILE__))) }
      let(:client_fqdn) { fact_on(client, 'fqdn') }
      # Need this for sudosh2
      it 'should set up needed repositories' do
        on(client, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X_Dependencies/script.rpm.sh | bash')
      end
      it 'should configure hiera' do
        set_hieradata_on(client, ERB.new(client_hieradata).result(binding))
      end
      it 'should apply the remote_access scenario without error' do
        apply_manifest_on(client, client_manifest, :catch_failures => true)
        apply_manifest_on(client, client_manifest, :catch_failures => true)
      end
      it 'should id test.user' do
        result = on(client, 'id test.user', :acceptable_exit_codes => [0])
        expect(result.stdout).to include("uid=10000(test.user)")
      end
      it 'should ssh from *server* to client' do
        on(ldap_server, "ssh -o StrictHostKeyChecking=no -i /tmp/testkey test.user@#{client} echo Logged in successfully")
      end
    end
  end
end
