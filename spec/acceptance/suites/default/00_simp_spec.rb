require 'spec_helper_acceptance'

test_name 'simp'

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

  let(:manifest) {
    <<-EOS
      # This would be in site.pp, or an ENC or classifier
      include 'simp_options'
      include 'simp'
      include 'simp::yum::repo::local_os_updates'
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

      it 'should set up simp_options through hiera' do
        set_hieradata_on(host, options)
      end

      # These boxes have no root password by default...
      it 'should set the root password' do
        on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
        on(host, 'echo password | passwd root --stdin')
      end

      it 'should set up needed repositories' do
        install_package host, 'epel-release'
        on host, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X_Dependencies/script.rpm.sh | bash'
      end

      it 'should put something in portreserve so the service starts' do
        # the portreserve service will fail unless something is configured
        on host, 'mkdir -p /etc/portreserve'
        on host, 'echo rndc/tcp > /etc/portreserve/named'
      end

      it 'should bootstrap in a few runs' do
        apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
        apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
        host.reboot
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end

  end
end
