require 'spec_helper'
require 'yaml'

# Tests the `simp:defaults` Sicura Compliance Engine profile end to end: with
# `compliance_engine::enforcement: [simp:defaults]` set in Hiera, the otherwise
# no-op `include simp::sysctl` must reproduce the catalog the class produced by
# default before the 11.0.0 blast-radius refactor.
#
# The "bare include is a no-op" regression specs live in sysctl_spec.rb and are
# intentionally left untouched -- they guard the safe default when the profile
# is NOT enforced.
describe 'simp::sysctl' do
  def self.profile_dir
    File.expand_path('../../../SIMP/compliance_profiles', __dir__)
  end

  # Every key the class set, with its value, before 11.0.0
  let(:pre_refactor_settings) do
    {
      'net.netfilter.nf_conntrack_max' => 655_360,
      'net.unix.max_dgram_qlen' => 50,
      'net.ipv4.neigh.default.gc_thresh3' => 2048,
      'net.ipv4.neigh.default.gc_thresh2' => 1024,
      'net.ipv4.neigh.default.gc_thresh1' => 32,
      'net.ipv4.neigh.default.proxy_qlen' => 92,
      'net.ipv4.neigh.default.unres_qlen' => 6,
      'net.ipv4.tcp_rmem' => '4096 98304 16777216',
      'net.ipv4.tcp_wmem' => '4096 65535 16777216',
      'net.ipv4.tcp_fin_timeout' => 30,
      'net.ipv4.tcp_rfc1337' => 1,
      'net.ipv4.tcp_keepalive_time' => 3600,
      'net.ipv4.tcp_mtu_probing' => 1,
      'net.ipv4.tcp_no_metrics_save' => 0,
      'net.core.rmem_max' => 16_777_216,
      'net.core.wmem_max' => 16_777_216,
      'net.core.optmem_max' => 20_480,
      'net.core.netdev_max_backlog' => 2048,
      'net.core.somaxconn' => 2048,
      'net.ipv4.tcp_tw_reuse' => 1,
      'fs.inotify.max_user_watches' => 102_400,
      'fs.suid_dumpable' => 0,
      'kernel.core_pattern' => '/var/core/%u_%g_%p_%t_%h_%e.core',
      'kernel.core_pipe_limit' => 0,
      'kernel.core_uses_pid' => 1,
      'kernel.dmesg_restrict' => 1,
      'kernel.panic' => 10,
      'kernel.randomize_va_space' => 2,
      'kernel.sysrq' => 0,
      'net.ipv4.conf.all.accept_redirects' => 0,
      'net.ipv4.conf.all.accept_source_route' => 0,
      'net.ipv4.conf.all.log_martians' => 1,
      'net.ipv4.conf.all.rp_filter' => 1,
      'net.ipv4.conf.all.secure_redirects' => 0,
      'net.ipv4.conf.all.send_redirects' => 0,
      'net.ipv4.conf.default.accept_redirects' => 0,
      'net.ipv4.conf.default.accept_source_route' => 0,
      'net.ipv4.conf.default.log_martians' => 1,
      'net.ipv4.conf.default.rp_filter' => 1,
      'net.ipv4.conf.default.secure_redirects' => 0,
      'net.ipv4.conf.default.send_redirects' => 0,
      'net.ipv4.icmp_echo_ignore_broadcasts' => 1,
      'net.ipv4.icmp_ignore_bogus_error_responses' => 1,
      'net.ipv4.tcp_challenge_ack_limit' => 2_147_483_647,
      'net.ipv4.tcp_max_syn_backlog' => 4096,
      'net.ipv4.tcp_syncookies' => 1,
      'net.ipv6.conf.all.accept_redirects' => 0,
      'net.ipv6.conf.all.accept_source_route' => 0,
      'net.ipv6.conf.all.autoconf' => 0,
      'net.ipv6.conf.all.disable_ipv6' => 1,
      'net.ipv6.conf.all.forwarding' => 0,
      'net.ipv6.conf.all.accept_ra' => 0,
      'net.ipv6.conf.default.accept_ra' => 0,
      'net.ipv6.conf.default.accept_ra_defrtr' => 0,
      'net.ipv6.conf.default.accept_ra_pinfo' => 0,
      'net.ipv6.conf.default.accept_ra_rtr_pref' => 0,
      'net.ipv6.conf.default.accept_redirects' => 0,
      'net.ipv6.conf.default.accept_source_route' => 0,
      'net.ipv6.conf.default.autoconf' => 0,
      'net.ipv6.conf.default.dad_transmits' => 0,
      'net.ipv6.conf.default.max_addresses' => 1,
      'net.ipv6.conf.default.router_solicitations' => 0,
    }
  end

  # --------------------------------------------------------------------------
  # Profile/check data integrity (no catalog compilation)
  # --------------------------------------------------------------------------
  context 'profile data' do
    let(:checks) do
      YAML.safe_load_file(File.join(self.class.profile_dir, 'checks.yaml'))['checks']
          .select { |id, _| id.start_with?('simp:defaults.simp.sysctl.') }
    end

    it 'maps each check ID to the parameter it names' do
      checks.each do |id, check|
        expect(check['settings']['parameter']).to eq("simp::sysctl::#{id.delete_prefix('simp:defaults.simp.sysctl.')}")
      end
    end

    it 'does not set the deprecated or never-defaulted parameters' do
      params = checks.values.map { |c| c['settings']['parameter'] }
      expect(params).not_to include('simp::sysctl::kernel__exec_shield')
      expect(params).not_to include('simp::sysctl::kernel__yama__ptrace_scope')
      expect(params).not_to include('simp::sysctl::unmanaged_sysctls')
      expect(params).not_to include('simp::sysctl::pam')
    end
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      next if os_facts[:kernel] == 'windows'

      context "on #{os}" do
        let(:hiera_config) do
          File.expand_path('../../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
        end

        # ------------------------------------------------------------------
        # Enforced, no overrides: reproduces the pre-refactor catalog.
        # ------------------------------------------------------------------
        context 'when enforcing simp:defaults' do
          let(:facts) { os_facts.merge(custom_hiera: 'simp_defaults_enforced') }

          it { is_expected.to compile.with_all_deps }

          it 'sets every pre-11.0.0 key to its pre-11.0.0 value' do
            pre_refactor_settings.each do |key, value|
              is_expected.to create_sysctl(key).with_value(value)
            end
          end

          it 'manages no other keys' do
            managed = catalogue.resources.select { |r| r.type == 'Sysctl' }.map(&:title)
            expect(managed).to match_array(pre_refactor_settings.keys)
          end

          it 'keeps nf_conntrack_max silent, as before' do
            is_expected.to create_sysctl('net.netfilter.nf_conntrack_max').with_silent(true)
          end

          it 'does not manage the core dump directory or the PAM core rule (simp_options::pam unset)' do
            is_expected.not_to create_file('/var/core')
            is_expected.not_to create_pam__limits__rule('prevent_core')
          end
        end

        context 'when enforcing simp:defaults with simp_options::pam' do
          let(:facts) { os_facts.merge(custom_hiera: 'simp_defaults_enforced_pam') }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_pam__limits__rule('prevent_core').with_value(0) }
          it { is_expected.not_to create_file('/var/core') }
        end

        # ------------------------------------------------------------------
        # Same Hiera config, enforcement disabled: bare include stays a no-op.
        # Proves the profile (not the backend wiring) is what restores the
        # behavior.
        # ------------------------------------------------------------------
        context 'without enforcement' do
          let(:facts) { os_facts.merge(custom_hiera: 'simp_defaults_disabled') }

          it { is_expected.to compile.with_all_deps }

          it 'manages nothing' do
            expect(catalogue.resources.select { |r| r.type == 'Sysctl' }).to be_empty
            is_expected.not_to create_file('/var/core')
            is_expected.not_to create_pam__limits__rule('prevent_core')
          end
        end

        # ------------------------------------------------------------------
        # Enforced + explicit site override: the override (higher Hiera
        # priority) must win over the profile value (middle priority).
        # ------------------------------------------------------------------
        context 'when explicit Hiera values override the profile' do
          let(:facts) { os_facts.merge(custom_hiera: 'simp_defaults_sysctl_override') }

          it { is_expected.to compile.with_all_deps }

          it 'uses the site value' do
            is_expected.to create_sysctl('net.core.somaxconn').with_value(4096)
            is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with_value(0)
          end

          it "removes a key the site set to 'absent'" do
            is_expected.to create_sysctl('kernel.sysrq').with_ensure('absent').without_value
          end

          it 'leaves a key the site set to ~ unmanaged' do
            is_expected.not_to create_sysctl('kernel.panic')
          end

          it 'still applies the profile values that were not overridden' do
            is_expected.to create_sysctl('kernel.dmesg_restrict').with_value(1)
            is_expected.to create_sysctl('net.ipv4.tcp_syncookies').with_value(1)
          end
        end
      end
    end
  end
end
