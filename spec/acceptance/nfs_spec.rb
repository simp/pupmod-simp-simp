require 'spec_helper_acceptance'

test_name 'simp nfs stock classes'

describe 'simp nfs stock classes' do

  let(:servers) { hosts_with_role( hosts, 'nfs_server' ) }
  let(:clients) { hosts_with_role( hosts, 'client' ) }
  let(:el7_server) { fact_on(only_host_with_role(servers, 'el7'), 'fqdn') }
  let(:el6_server) { fact_on(only_host_with_role(servers, 'el6'), 'fqdn') }

  context 'with exported home directories' do

    it 'should install and configure nfs properly' do

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

        # Set up simp and epel repos
        simp_repo = os_release == '6' ? '4.2.X' : '5.1.X'
        on node, "wget https://bintray.com/simp/#{simp_repo}/rpm -O /etc/yum.repos.d/bintray-simp-#{simp_repo}.repo"
        epel_manifest =
<<-EOM
exec { 'Install EPEL':
  command   => '/usr/bin/curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-#{os_release}.noarch.rpm && yum -y localinstall epel-release-latest-#{os_release}.noarch.rpm && /bin/sed -i "/mirrorlist/d" /etc/yum.repos.d/epel.repo && /bin/sed -i "s/#baseurl/baseurl/" /etc/yum.repos.d/epel.repo',
  cwd       => '/tmp',
  creates   => '/etc/yum.repos.d/epel.repo'
}
EOM
        apply_manifest_on(node, epel_manifest, :catch_failures => true)

        # Construct common hieradata
        domains = fact_on(node, 'domain').split('.')
        domains.map! { |d|
          "dc=#{d}"
        }
        domains = domains.join(',')
        hieradata =
<<-EOM
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
nfs::server: #{server}
sssd::domains:
 - 'LDAP'
use_ldap: true
pam::wheel_group : 'administrators'

# Need to tell our modules where our certs live!
# This is a good test of the case where users don't want to use our PKI module.
pki_dir : '/etc/pki/simp-testing/pki'

openldap::client::tls_cacertdir : "%{hiera('pki_dir')}/cacerts"
openldap::client::tls_cert : "%{hiera('pki_dir')}/public/%{fqdn}.pub"
openldap::client::tls_key: "%{hiera('pki_dir')}/private/%{fqdn}.pem"

openldap::pam::tls_cacertdir : "%{hiera('pki_dir')}/cacerts"
openldap::pam::tls_cert : "%{hiera('pki_dir')}/public/%{fqdn}.pub"
openldap::pam::tls_key: "%{hiera('pki_dir')}/private/%{fqdn}.pem"

stunnel::ca_source : "%{hiera('pki_dir')}/cacerts"
stunnel::cert : "%{hiera('pki_dir')}/public/%{fqdn}.pub"
stunnel::key : "%{hiera('pki_dir')}/private/%{fqdn}.pem"

use_simp_pki : false
use_iptables : true

ssh::server::conf::permitrootlogin : true
ssh::server::conf::authorizedkeysfile : ".ssh/authorized_keys"

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
        manifest = "hiera_include('classes')\n"

        # Construct server hieradata; export home directories.
        if servers.include?(node)
          hieradata <<
<<-EOM
nfs::is_server: true
nfs::server::client_ips: 'ALL'
simp::nfs::export_home::create_home_dirs: true
EOM
          manifest <<
<<-EOM
include 'simp::nfs::export_home'
include 'simp::ldap_server'

file { '/etc/openldap/pki':
  source  => '/etc/pki/simp-testing/pki',
  recurse => true,
  group   => 'ldap',
  mode    => 'g+r',
  notify  => Class['openldap::server']
}

EOM
        end

        set_hieradata_on(node, hieradata, 'default')
        on node, ('mkdir -p /usr/local/sbin/simp')
        apply_manifest_on(node, manifest, :catch_failures => false)
      end
    end
  end
end
