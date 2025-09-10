require 'spec_helper'

# We have to test simp::scenario::base via simp, because
# simp::scenario::base is private.  To take advantage of hooks
# built into puppet-rspec, the class described needs to be the class
# instantiated, i.e., simp.
describe 'simp' do
  def server_facts_hash
    {
      'serverversion' => Puppet.version,
      'servername'    => 'puppet.bar.baz',
      'serverip'      => '1.2.3.4',
    }
  end

  on_supported_os.each do |os, os_facts|
    # Private classes should never be called on unsupported OSs
    next if os_facts[:kernel] == 'windows'

    context "on #{os}" do
      let(:facts) do
        facts = os_facts.dup
        facts[:openssh_version] = '5.8'
        facts[:augeas] = { 'version' => '1.2.3' }
        facts[:puppet_vardir] = '/opt/puppetlabs/puppet/cache'
        facts[:puppet_settings] = os_facts[:puppet_settings].merge(
          'main' => {
            'ssldir' => '/opt/puppetlabs/puppet/vardir',
          },
          'agent' => {
            'server' => 'puppet.bar.baz',
          },
        )

        facts
      end

      context 'default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::scenario::base') }
        it { is_expected.to create_runlevel('3') }
        it { is_expected.to create_class('simp::sssd::client') }
        it { is_expected.to create_class('simp::sudoers') }
        it { is_expected.to create_class('simp::ctrl_alt_del') }
        it { is_expected.to create_class('simp::root_user') }
        # simp_options::pam is not set in spec/fixtures/hieradata/default.yaml
        it { is_expected.not_to create_class('simp::pam_limits::max_logins') }
        it { is_expected.to create_class('postfix') }
        it { is_expected.not_to create_class('postfix::server') }
        # simp_options::ldap is not set in spec/fixtures/hieradata/default.yaml
        it { is_expected.not_to create_class('simp_openldap::client') }
        it { is_expected.to create_class('simp::rc_local') }
      end

      context "runlevel = 'graphical'" do
        let(:params) { { runlevel: 'graphical' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_runlevel('graphical') }
      end

      context 'sssd = false' do
        let(:params) { { sssd: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('simp::sssd::client') }
      end

      context 'stock_sssd = false' do
        let(:params) { { stock_sssd: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('simp::sssd::client') }
      end

      context 'use_sudoers_aliases = false' do
        let(:params) { { use_sudoers_aliases: false } }

        it { is_expected.to compile.with_all_deps }
        # SIMP-6133
        pending { is_expected.not_to create_class('simp::sudoers') }
      end

      context 'manage_ctrl_alt_del = false' do
        let(:params) { { manage_ctrl_alt_del: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('simp::ctrl_alt_del') }
      end

      context 'manage_root_metadata = false' do
        let(:params) { { manage_root_metadata: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('simp::root_user') }
      end

      context 'restrict_max_logins = false' do
        let(:params) { { restrict_max_logins: false, pam: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('simp::pam_limits::max_logins') }
      end

      context 'pam = true' do
        let(:params) { { pam: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::pam_limits::max_logins') }
      end

      context 'mail_server = false' do
        let(:params) { { mail_server: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('postfix') }
        it { is_expected.not_to create_class('postfix::server') }
      end

      context "mail_server = 'remote'" do
        let(:params) { { mail_server: 'remote' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('postfix::server') }
      end

      context 'ldap = true' do
        let(:params) { { ldap: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_openldap::client') }
      end

      context 'ipa fact set ' do
        let(:facts) do
          super().merge(
            ipa: {
              domain: 'ipa.example.com',
              server: 'ipaserver.example.com',
            },
          )
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('simp_openldap::client') }
      end

      context 'manage_rc_local = false' do
        let(:params) { { manage_rc_local: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('simp::rc_local') }
      end
    end
  end
end
