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
      include 'simp'
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
sssd::domains: ['LDAP']
simp::yum::servers: ['#{host_fqdn}']

# Settings required for acceptance test
simp_options::rsync: false
simp_options::clamav: false
simp_options::pki: true
simp_options::pki::source: '/etc/pki/simp-testing/pki'
simp_options::trusted_nets: ['ALL']
simp::yum::os_update_url: http://mirror.centos.org/centos/$releasever/os/$basearch/
simp::yum::enable_simp_repos: false

        EOF
      }

      it 'should set up simp_options through hiera' do
        set_hieradata_on(host, options)
      end

      it 'should set up needed repositories' do
        install_package host, 'epel-release'
        on host, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X_Dependencies/script.rpm.sh | bash'
      end

      it 'should work with default values' do
        apply_manifest_on(host, manifest, :catch_failures => true)
        apply_manifest_on(host, manifest, :catch_failures => true)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end

  end
end
