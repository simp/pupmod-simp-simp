require 'spec_helper'
require 'yaml'

# Tests the `simp:defaults` Sicura Compliance Engine profile end to end: with
# `compliance_engine::enforcement: [simp:defaults]` set in Hiera, the otherwise
# no-op `include simp::kmod_blacklist` must reproduce the catalog the class
# produced by default before the 10.0.0 blast-radius refactor.
#
# The "bare include is a no-op" regression specs live in kmod_blacklist_spec.rb
# and are intentionally left untouched -- they guard the safe default when the
# profile is NOT enforced.
describe 'simp::kmod_blacklist' do
  def self.profile_dir
    File.expand_path('../../../SIMP/compliance_profiles', __dir__)
  end

  let(:stock_blacklist) do
    ['bluetooth', 'cramfs', 'dccp', 'dccp_ipv4',
     'dccp_ipv6', 'freevxfs', 'hfs', 'hfsplus',
     'ieee1394', 'jffs2', 'net-pf-31', 'rds', 'sctp',
     'squashfs', 'tipc', 'udf', 'usb-storage']
  end

  # --------------------------------------------------------------------------
  # Profile/check data integrity (no catalog compilation)
  # --------------------------------------------------------------------------
  context 'profile data' do
    let(:checks) { YAML.safe_load_file(File.join(self.class.profile_dir, 'checks.yaml'))['checks'] }
    let(:profile) { YAML.safe_load_file(File.join(self.class.profile_dir, 'profile-simp_defaults.yaml'))['profiles']['simp:defaults'] }

    it 'lists exactly the defined checks (no orphans, none missing)' do
      expect(profile['checks'].keys.sort).to eq(checks.keys.sort)
    end

    it 'only manages simp::kmod_blacklist parameters' do
      params = checks.values.map { |c| c['settings']['parameter'] }
      expect(params).to all(start_with('simp::kmod_blacklist::'))
    end

    it 'uses the simp:defaults check ID namespace' do
      expect(checks.keys).to all(start_with('simp:defaults.simp.kmod_blacklist.'))
    end

    it 'carries the pre-10.0.0 SCAP Security Guide blacklist' do
      expect(checks['simp:defaults.simp.kmod_blacklist.blacklist']['settings']['value']).to eq(stock_blacklist)
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

          it 'blacklists all the SCAP kmods' do
            is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content(stock_blacklist.map { |x| "install #{x} /bin/true" }.join("\n") + "\n")
            is_expected.to create_file('/etc/modprobe.d/00_simp_disable.conf').with_ensure('absent')

            stock_blacklist.each do |mod|
              is_expected.to create_kmod__blacklist(mod).with_ensure('present')
            end
          end

          context 'on a system with kernel.modules_disabled available' do
            let(:facts) do
              os_facts.merge(custom_hiera: 'simp_defaults_enforced', 'simplib_sysctl' => { 'kernel.modules_disabled' => 0 })
            end

            it 'manages module locking in the unlocked state, as before' do
              is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_enable(false).with_stage('main')
              is_expected.not_to create_stage('simp_modprobe_lock')
              is_expected.not_to create_sysctl('kernel.modules_disabled')
            end
          end

          context 'on a system with kernel modules locked' do
            let(:facts) do
              os_facts.merge(custom_hiera: 'simp_defaults_enforced', 'simplib_sysctl' => { 'kernel.modules_disabled' => 1 })
            end

            it 'unlocks the modules and notifies for reboot, as before' do
              is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_enable(false)
              is_expected.to create_sysctl('kernel.modules_disabled').with_value(0)
              is_expected.to create_reboot_notify('kernel.modules_disabled unlock')
            end
          end
        end

        # ------------------------------------------------------------------
        # Same Hiera config, enforcement disabled: bare include stays a no-op.
        # Proves the profile (not the backend wiring) is what restores the
        # behavior.
        # ------------------------------------------------------------------
        context 'without enforcement' do
          let(:facts) do
            os_facts.merge(custom_hiera: 'simp_defaults_disabled', 'simplib_sysctl' => { 'kernel.modules_disabled' => 1 })
          end

          it { is_expected.to compile.with_all_deps }

          it 'manages nothing' do
            is_expected.not_to create_file('/etc/modprobe.d/zz_simp_disable.conf')
            is_expected.not_to create_file('/etc/modprobe.d/00_simp_disable.conf')
            is_expected.not_to create_class('simp::kmod_blacklist::lock_modules')
            is_expected.not_to create_sysctl('kernel.modules_disabled')

            stock_blacklist.each do |mod|
              is_expected.not_to create_kmod__blacklist(mod)
            end
          end
        end

        # ------------------------------------------------------------------
        # Enforced + explicit site override: the override (higher Hiera
        # priority) must win over the profile value (middle priority).
        # ------------------------------------------------------------------
        context 'when an explicit Hiera value overrides the profile' do
          let(:facts) do
            os_facts.merge(custom_hiera: 'simp_defaults_with_override', 'simplib_sysctl' => { 'kernel.modules_disabled' => 0 })
          end

          it { is_expected.to compile.with_all_deps }

          it 'uses the overridden blacklist instead of the profile default' do
            is_expected.to create_file('/etc/modprobe.d/zz_simp_disable.conf').with_content("install nfs /bin/true\n")
            is_expected.to create_kmod__blacklist('nfs').with_ensure('present')

            stock_blacklist.each do |mod|
              is_expected.not_to create_kmod__blacklist(mod)
            end
          end

          it 'still applies the profile values that were not overridden' do
            is_expected.to create_class('simp::kmod_blacklist::lock_modules').with_enable(false)
          end
        end
      end
    end
  end
end
