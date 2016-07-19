require 'spec_helper_acceptance'

test_name 'simp nfs stock classes'

describe 'simp nfs stock classes' do

  let(:servers) { hosts_with_role( hosts, 'nfs_server' ) }
  let(:clients) { hosts_with_role( hosts, 'client' ) }
  let(:el7_server) { fact_on(only_host_with_role(servers, 'el7'), 'fqdn') }
  let(:el6_server) { fact_on(only_host_with_role(servers, 'el6'), 'fqdn') }

  context 'with exported home directories' do

    it 'should install nfs, openldap, and create test.user' do

      # Determine appropriate server for each node
      [servers, clients].flatten.each do |node|
        os = fact_on(node, 'operatingsystem')
        if os == 'CentOS' then
          os_release = fact_on(node, 'operatingsystemmajrelease')
          if os_release == '6' then server = el6_server
          elsif os_release == '7' then server = el7_server
          else
            STDERR.puts "#{os_release} not a supported OS release"
            next
          end
        else
          STDERR.puts "OS #{os} not supported"
          next
        end

        # Construct common hieradata
        domains = fact_on(node, 'domain').split('.')
        domains.map! { |d|
          "dc=#{d}"
        }
        domains = domains.join(',')
        hieradata = <<-EOM
---
client_nets:
 - 'ALL'
ldap::uri:
 - 'ldap://#{server}'
ldap::base_dn: '#{domains}'
ldap::bind_dn: 'cn=hostAuth,ou=Hosts,#{domains}'
ldap::bind_pw: 'foobarbaz'
ldap::bind_hash: '{SSHA}BNPDR0qqE6HyLTSlg13T0e/+yZnSgYQz'
ldap::sync_dn: 'cn=LDAPSync,ou=Hosts,#{domains}'
ldap::sync_pw: 'foobarbaz'
ldap::sync_hash: '{SSHA}BNPDR0qqE6HyLTSlg13T0e/+yZnSgYQz'
ldap::root_dn: 'cn=LDAPAdmin,ou=People,#{domains}'
ldap::root_hash: '{SSHA}BNPDR0qqE6HyLTSlg13T0e/+yZnSgYQz'
ldap::master: 'ldap://#{server}'
# suP3rP@ssw0r!
ldap::root_hash: "{SSHA}ZcqPNbcqQhDNF5jYTLGl+KAGcrHNW9oo"
nfs::server: "#{server}"
sssd::domains:
 - 'LDAP'
use_ldap: true
pam::wheel_group : 'administrators'

pki_dir : '/etc/pki/simp-testing/pki'
pki::private_key_source : "file://%{hiera('pki_dir')}/private/%{::fqdn}.pem"
pki::public_key_source : "file://%{hiera('pki_dir')}/public/%{::fqdn}.pub"
pki::cacerts_sources :
  - "file://%{hiera('pki_dir')}/cacerts"

#openldap::client::tls_cacertdir : "%{hiera('pki_dir')}/cacerts"
#openldap::client::tls_cert : "%{hiera('pki_dir')}/public/%{fqdn}.pub"
#openldap::client::tls_key: "%{hiera('pki_dir')}/private/%{fqdn}.pem"

#openldap::pam::tls_cacertdir : "/etc/nslcd.d/pki/cacerts"
#openldap::pam::tls_cert : "/etc/nslcd.d/pki/public/%{fqdn}.pub"
#openldap::pam::tls_key: "/etc/nslcd.d/pki/private/%{fqdn}.pem"

#stunnel::ca_source : "%{hiera('pki_dir')}/cacerts"
#stunnel::cert : "%{hiera('pki_dir')}/public/%{fqdn}.pub"
#stunnel::key : "%{hiera('pki_dir')}/private/%{fqdn}.pem"

use_iptables : true

ssh::server::conf::permitrootlogin : true
ssh::server::conf::authorizedkeysfile : ".ssh/authorized_keys"
# Use fallback ciphers/macs to ensure ssh capability on any platform
ssh::server::conf::ciphers:
 - 'aes256-cbc'
 - 'aes192-cbc'
 - 'aes128-cbc'
ssh::server::conf::macs:
 - 'hmac-sha1'

# For testing
simp::is_mail_server : false

classes :
  - "openldap::pam"
  - "pam::access"
  - "pam::wheel"
  - "simp"
  - "simp::admin"
  - "simp::nfs::home_client"
  - "simplib::nsswitch"
  - "ssh"
  - "tcpwrappers"
        EOM

        manifest = <<-EOM
          hiera_include('classes')

          if $::openldap::use_nscd {
            file { '/etc/nslcd.d/pki':
              source => '/etc/pki/simp-testing/pki',
              recurse => true,
              group => 'nslcd',
              mode => 'g+r',
              notify => Service['nslcd']
            }
          }
        EOM

        # Construct server hieradata; export home directories.
        if servers.include?(node)
          hieradata << <<-EOM
nfs::is_server: true
nfs::server::client_ips: 'ALL'
simp::nfs::export_home::create_home_dirs: true
          EOM

          manifest << <<-EOM
            include 'simp::nfs::export_home'
            include 'simp::ldap_server'
          EOM
        end

        # Apply
        set_hieradata_on(node, hieradata, 'default')
        on(node, ('mkdir -p /usr/local/sbin/simp'))
        apply_manifest_on(node, manifest, :catch_failures => true)

        # Create test.user
        if servers.include?(node)
          on(node, "cat <<EOF > /root/user_ldif.ldif
dn: cn=test.user,ou=Group,#{domains}
objectClass: posixGroup
objectClass: top
cn: test.user
gidNumber: 10000
description: 'Test user'

dn: uid=test.user,ou=People,#{domains}
uid: test.user
cn: test.user
givenName: Test
sn: User
mail: test.user@funurl.net
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
objectClass: ldapPublicKey
shadowMax: 180
shadowMin: 1
shadowWarning: 7
shadowLastChange: 10701
sshPublicKey:
loginShell: /bin/bash
uidNumber: 10000
gidNumber: 10000
homeDirectory: /home/test.user
#suP3rP@ssw0r!
userPassword: {SSHA}r2GaizHFWY8pcHpIClU0ye7vsO4uHv/y
pwdReset: TRUE
EOF")

          on(node, "cat <<EOF > /root/group_ldif.ldif
dn: cn=administrators,ou=Group,#{domains}
changetype: modify
add: memberUid
memberUid: test.user
EOF")


          # Create test.user and add to administrators
          on(node, "ldapadd -D cn=LDAPAdmin,ou=People,#{domains} -H ldap://#{server} -w suP3rP@ssw0r! -x -Z -f /root/user_ldif.ldif")
          on(node, "ldapmodify -D cn=LDAPAdmin,ou=People,#{domains} -H ldap://#{server} -w suP3rP@ssw0r! -x -Z -f /root/group_ldif.ldif")

          # Ensure the cache is built, don't wait for enum timeout
          result = on(node, "pgrep -x sssd", :accept_all_exit_codes => true)

          if result.exit_code.to_s == '0'
            on(node, "service sssd restart")
          else
            on(node, "service nscd reload")
            on(node, "service nscd restart")
            on(node, "service nslcd restart")
          end

          user_info = on(node, "id test.user", :acceptable_exit_codes => [0])
          expect(user_info.stdout).to match(/.*uid=10000\(test.user\).*gid=10000\(test.user\)/)

          # Create test.user's homedir via cron, and ensure it gets mounted
          on(node, "/etc/cron.hourly/create_home_directories.rb")
          on(node, "runuser -l test.user -c 'touch ~/testfile'")
          mount = on(node, "mount")
          expect(mount.stdout).to match(/127.0.0.1:\/home\/test.user.*nfs/)
        end
      end
    end

    it 'should have file propagation to the clients' do
      clients.each do |node|
        on(node, "ls /home/test.user/testfile", :acceptable_exit_codes => [0])
      end
    end
  end
end
