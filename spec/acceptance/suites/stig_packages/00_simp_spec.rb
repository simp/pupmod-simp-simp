require 'spec_helper_acceptance'

test_name 'simp'

describe 'simp class' do
  let(:manifest) {
    <<-EOS
      include 'simp_options'
      include 'simp'
      include 'simp::stig_packages'
      include 'simp::yum::repo::local_os_updates'
      package { 'screen':
        ensure => 'absent'
        }
      package { 'rsh-server':
        ensure => 'installed'
        }
      package { 'esc':
        ensure => 'latest'
        }
    EOS
  }

  context 'on each host' do
    hosts.each do |host|
      let(:host_fqdn) { fact_on(host, 'fqdn') }
      let(:options) {
      <<-EOF
# Mandatory Settings
simp_options::dns::servers: ['8.8.8.8']
simp_options::puppet::server: #{host_fqdn}
simp_options::puppet::ca: #{host_fqdn}
simp_options::ntpd::servers: ['time.nist.gov']
simp_options::ldap::bind_pw: 's00per sekr3t!'
simp_options::ldap::bind_hash: '{SSHA}foobarbaz!!!!'
simp_options::ldap::sync_pw: 's00per sekr3t!'
simp_options::ldap::sync_hash: '{SSHA}foobarbaz!!!!'
simp_options::ldap::root_hash: '{SSHA}foobarbaz!!!!'
# simp_options::log_servers: ['#{host_fqdn}']
sssd::domains: ['LOCAL']
simp::yum::repo::simp::servers: ['#{host_fqdn}']
simp::yum::repo::local_os_updates::servers:
- '#{host_fqdn}'
- http://mirror.centos.org/centos/$releasever/os/$basearch/

# Settings required for acceptance test, some may be required
simp::scenario: simp
simp_options::rsync: false
simp_options::clamav: false
simp_options::pki: true
simp_options::pki::source: '/etc/pki/simp-testing/pki'
simp_options::trusted_nets: ['ALL']

# Settings to make beaker happy
ssh::server::conf::permitrootlogin: true
ssh::server::conf::authorizedkeysfile: .ssh/authorized_keys
      EOF
    }
        context 'with default params' do
          let(:extraoptions) {
            <<-EOF
simp::stig_pkg_enforce: true
            EOF
          }
          it 'should set up simp' do
            set_hieradata_on(host, options + extraoptions )
          end

          it 'should do configuration' do
            on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
            on(host, 'echo "root:password" | chpasswd --crypt-method SHA256')
            on host, 'mkdir -p /etc/portreserve'
            on host, 'echo rndc/tcp > /etc/portreserve/named'
          end

          it 'should set up needed repositories' do
            install_package host, 'epel-release'
            on host, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X_Dependencies/script.rpm.sh | bash'
          end

          it 'should install forbidden package' do
            install_package host, 'ypserv'
          end

          it 'should bootstrap in a few runs' do
            apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
            apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
            host.reboot
          end

          it 'should display warning' do
            result = apply_manifest_on(host, manifest, :catch_failures => true)
            expect(result.stderr).to include("A Package resource for rsh-server exists in the catalog and is set to: present")
            expect(result.stderr).to include("A Package resource for screen exists in the catalog and is set to: absent")
            expect(result.stderr).not_to include("Package esc with ensure present would have been added")
            ['vsftpd', 'telnet-server','ypserv'].each do |pkg|
              expect(result.stderr).to include("Package #{pkg} with ensure absent would have been added")
            end
            ['firewalld','authconfig-gtk'].each do |pkg|
              expect(result.stderr).to include("Package #{pkg} with ensure present would have been added")
            end
          end

          ['esc','ypserv', 'rsh-server'].each do |pkg|
            describe package(pkg) do
              it {is_expected.to be_installed}
            end
          end
          describe package('screen') do
            it {is_expected.not_to be_installed}
          end

        end
        context 'with mode set to enforcing and warning set to false' do
          let(:moreoptions) {
            <<-EOH
simp::stig_pkg_enforce: true
simp::stig_packages::mode: 'enforcing'
simp::stig_packages::enable_warnings: false
           EOH
          }

          it 'should set up simp_options through hiera' do
            set_hieradata_on(host, options + moreoptions)
          end

          it 'should not display warning' do
            result = apply_manifest_on(host, manifest, :catch_failures => true)
            # It should not printout the mismatch warning because warning = false
            expect(result.stderr).not_to include("A Package resource for rsh-server exists in the catalog and is set to: present")
            # It should not print out the other warnings because mode = 'enforcing'
            ['vsftpd', 'telnet-server','ypserv','firewalld','authconfig-gtk'].each do |pkg|
              expect(result.stderr).not_to include("Package #{pkg} with ensure")
            end
          end
          # These should be installed because of package resources.
          ['esc','authconfig-gtk','rsh-server'].each do |pkg|
            describe package(pkg) do
              it {is_expected.to be_installed}
            end
          end
          # These should be installed because they are in the add hash.
          ['authconfig-gtk','firewalld'].each do |pkg|
            describe package(pkg) do
              it {is_expected.to be_installed}
            end
          end
          # Screen should be absent because of resource and ypserv should have
          # been removed because it is in the remove hash.
          ['screen', 'ypserv'].each do |pkg|
            describe package(pkg) do
              it {is_expected.not_to be_installed}
            end
          end

       end
    end
  end
end
