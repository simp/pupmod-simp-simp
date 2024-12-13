require 'spec_helper_acceptance'

test_name 'simp "one_shot" scenario'

describe 'simp "one_shot" scenario' do
  def has_puppet(host)
    on(host, 'test -f /opt/puppetlabs/bin/puppet', accept_all_exit_codes: true).exit_code == 0
  end

  def finalize_running?(host)
    puppet_running = on(host, 'pgrep -x puppet', accept_all_exit_codes: true).exit_code == 0

    return puppet_running if puppet_running

    (on(host, 'pgrep simp_one_shot_finalize', accept_all_exit_codes: true).exit_code == 0)
  end

  def wait_for_finalize(host, timeout = 500)
    begin
      Timeout.timeout(timeout) do
        sleep(5) while finalize_running?(host)
      end
    rescue Timeout::Error
      raise("Error: finalize did not finish within #{timeout} seconds")
    end

    # Allow a little more time before hitting the system again
    sleep(5)
  end

  let(:manifest) do
    <<-EOS
      # This would be in site.pp, or an ENC or classifier
      include 'simp_options'
      include 'simp'
    EOS
  end

  let(:hieradata) do
    <<-EOF
# Mandatory Settings
simp_options::dns::servers: ['8.8.8.8']
simp_options::puppet::server: #{host_fqdn}
simp_options::puppet::ca: #{host_fqdn}

# Settings required for acceptance test, some may be required
simp::scenario: one_shot
simp::one_shot::user_ssh_authorized_key: #{ssh_authorized_key}

# 'simp_one_shot'
simp::one_shot::user_password: '$6$jQ3VdTtWGDnCyqI8$triqoAkFqI8nDR9jNJeawj9.kqVh0KPQLjjw35vfB3.33Gb76Di/C4dBmDSUbtsFnZnPwIVB4iKGYTyigDqlj/'
simp::one_shot::finalize_debug: true

# Disable network stuff
simp_options::rsync: false
simp_options::clamav: false
simp_options::ldap: false

# Enable everything else
simp_options::auditd: true
simp_options::firewall: true
simp_options::haveged: true
simp_options::logrotate: true
simp_options::pam: true
simp_options::sssd: true
simp_options::syslog: true
simp_options::tcpwrappers: true
simp_options::pki: true
simp_options::sssd: true

simp_options::pki::source: '/etc/pki/simp-testing/pki'
simp_options::trusted_nets: ['ALL']

# Settings to make beaker happy
ssh::server::conf::permitrootlogin: true
ssh::server::conf::authorizedkeysfile: .ssh/authorized_keys

sssd::enable_files_domain: true

pam::access::users:
  vagrant:
    origins:
      - ALL
    permission: '+'

sudo::user_specifications:
  vagrant_sudo:
    user_list: ['vagrant']
    cmnd: ['/bin/su']

useradd::securetty:
  - ANY_SHELL
    EOF
  end

  hosts.each do |host|
    let(:host_fqdn) { fact_on(host, 'fqdn') }
    let(:ssh_authorized_key) do
      on(host, 'cat ~/.ssh/authorized_keys').stdout.strip.lines.first.split(%r{\s+})[1]
    end

    it 'sets up simp_options through hiera' do
      set_hieradata_on(host, hieradata)
    end

    # These boxes have no root password by default...
    it 'sets the root password' do
      on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
      on(host, 'echo "root:password" | chpasswd --crypt-method SHA256')
    end

    it 'bootstraps in a few runs' do
      if has_puppet(host)
        apply_manifest_on(host, manifest, accept_all_exit_codes: true)
        wait_for_finalize(host)
      end

      # Handle items that require a reboot
      host.reboot

      if has_puppet(host)
        apply_manifest_on(host, manifest, accept_all_exit_codes: true)
        wait_for_finalize(host)
      end
    end

    it 'waits for finalization' do
      wait_for_finalize(host)
    end

    it 'noes longer have puppet installed' do
      on(host, 'test ! -d /opt/puppetlabs')
    end

    it 'noes longer have the SIMP PKI keys installed' do
      on(host, 'test ! -d /etc/pki/simp')
    end

    it 'noes longer have the finalization script installed' do
      on(host, 'test ! -f /usr/local/sbin/simp_one_shot_finalize.sh')
    end
  end
end
