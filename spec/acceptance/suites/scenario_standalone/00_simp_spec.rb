require 'spec_helper_acceptance'

test_name 'simp "standalone" scenario'

describe 'simp "standalone" scenario' do
  def has_puppet(host)
    on(host, 'test -f /opt/puppetlabs/bin/puppet', :accept_all_exit_codes => true).exit_code == 0
  end

  let(:manifest) {
    <<-EOS
      # This would be in site.pp, or an ENC or classifier
      include 'simp_options'
      include 'simp'
    EOS
  }

  let(:hieradata) {<<-EOF
# Mandatory Settings
simp_options::dns::servers: ['8.8.8.8']
simp_options::puppet::server: #{host_fqdn}
simp_options::puppet::ca: #{host_fqdn}
sssd::domains: ['LOCAL']

# Settings required for acceptance test, some may be required
simp::scenario: standalone
simp::standalone::user_ssh_authorized_key: #{ssh_authorized_key}

# 'simp_standalone'
simp::standalone::user_password: '$6$jQ3VdTtWGDnCyqI8$triqoAkFqI8nDR9jNJeawj9.kqVh0KPQLjjw35vfB3.33Gb76Di/C4dBmDSUbtsFnZnPwIVB4iKGYTyigDqlj/'

simp_options::rsync: false
simp_options::clamav: false
simp_options::pki: true
simp_options::pki::source: '/etc/pki/simp-testing/pki'
simp_options::trusted_nets: ['ALL']

# Settings to make beaker happy
ssh::server::conf::permitrootlogin: true
ssh::server::conf::authorizedkeysfile: .ssh/authorized_keys
useradd::securetty:
  - ANY_SHELL
    EOF
  }

  hosts.each do |host|
    let(:host_fqdn) { fact_on(host, 'fqdn') }
    let(:ssh_authorized_key) {
      on(host, 'cat ~/.ssh/authorized_keys').stdout.strip.lines.first.split(/\s+/)[1]
    }

    it 'should set up simp_options through hiera' do
      set_hieradata_on(host, hieradata)
    end

    # These boxes have no root password by default...
    it 'should set the root password' do
      on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
      on(host, 'echo "root:password" | chpasswd')
    end

    it 'should bootstrap in a few runs' do
      if has_puppet(host)
        apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
        sleep(10)
      end
      if has_puppet(host)
        apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
        sleep(10)
        host.reboot
      end
      if has_puppet(host)
        apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
        sleep(10)
      end
    end

    it 'should no longer have puppet installed' do
      on(host, 'test ! -d /opt/puppetlabs')
    end

    it 'should no longer have the SIMP PKI keys installed' do
      on(host, 'test ! -d /etc/pki/simp')
    end

    it 'should no longer have the finalization script installed' do
      on(host, 'test ! -f /usr/local/sbin/simp_standalone_finalize.sh')
    end
  end
end
