require 'spec_helper_acceptance'
require 'erb'

test_name 'simp class'

describe 'simp class' do
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

  ldap_servers = hosts_with_role(hosts, 'ldap_server')
  #client = hosts_with_role(hosts, 'client')

  ldap_servers.each do |ldap_server|
    context "test authentication using remote_access scenario" do
      let(:server_fqdn) { fact_on(ldap_server, 'fqdn') }
      let(:base_dn) { fact_on(ldap_server, 'domain').split('.').map{ |d| "dc=#{d}" }.join(',') }
      let(:server_hieradata)      { File.read(File.expand_path('templates/server_hieradata.yaml.erb', File.dirname(__FILE__))) }
      let(:add_testuser)          { File.read(File.expand_path('templates/add_testuser.ldif.erb', File.dirname(__FILE__))) }
      let(:add_testuser_to_admin) { File.read(File.expand_path('templates/add_testuser_to_admin.ldif.erb', File.dirname(__FILE__))) }

      context "set up simp_openldap::server on #{ldap_server}" do
        # Required for simp ldap password policy
        it 'should set up needed repositories' do
          on host, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X_Dependencies/script.rpm.sh | bash'
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

          on(ldap_server, "ldapadd -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r! -x -f /tmp/add_testuser.ldif")

          result = on(ldap_server, "ldapsearch -Z -LLL -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r! -x uid=test.user")
          expect(result.stdout).to include("dn: uid=test.user,ou=People,#{base_dn}")
        end
        it 'should be able to add user to group' do
          create_remote_file(ldap_server, '/tmp/add_testuser_to_admin.ldif', ERB.new(add_testuser_to_admin).result(binding))

          on(ldap_server, "ldapmodify -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r! -x -f /tmp/add_testuser_to_admin.ldif")

          result = on(ldap_server, "ldapsearch -Z -LLL -D cn=LDAPAdmin,ou=People,#{base_dn} -H ldap://#{server_fqdn} -w suP3rP@ssw0r! -x cn=test.user")
          expect(result.stdout).to include("dn: cn=test.user,ou=Group,#{base_dn}")
        end
      end
    end
  end
end
