require 'spec_helper'

describe 'simp::ipa::install' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      context 'with ensure => present and $facts[ipa] absent' do
        context 'with minimal parameters' do
          let(:params) {{
            ensure: 'present'
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::ipa::install') }
          it { is_expected.to create_package('ipa-client') }
          it { is_expected.to create_exec('ipa-client-install install') \
            .with_command('ipa-client-install --unattended --noac') }
          if os_facts[:os][:release][:major].to_i < 7
            it { is_expected.to create_package('ipa-admintools') }
          end
        end

        context 'with all explicit parameters' do
          let(:params) {{
            ensure: 'present',
            password: 'password',
            principal: 'admin',
            server: ['ipa.ipa.example.local','ipa2.ipa.example.local'],
            ntp_server: ['192.168.1.1','192.168.1.2'],
            domain: 'ipa.example.local',
            realm: 'IPA.EXAMPLE.LOCAL',
            hostname: 'client.ipa.example.local',
            no_ac: false,
          }}
          it { is_expected.to compile.with_all_deps }
          expected = [
            'ipa-client-install --unattended',
            '--password=password',
            '--principal=admin',
            '--server=ipa.ipa.example.local',
            '--server=ipa2.ipa.example.local',
            '--domain=ipa.example.local',
            '--realm=IPA.EXAMPLE.LOCAL',
            '--hostname=client.ipa.example.local',
          ].join(' ')
          it { is_expected.to create_exec('ipa-client-install install').with_command(expected) }
        end
      end

      context 'with ensure => present and $facts[ipa] present' do
        let(:params) {{
          ensure: 'present',
          domain: 'testipa.example.local'
        }}
        let(:facts) { super().merge(
          ipa: {
            domain: 'testipa.example.local'
          }
        )}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_exec('ipa-client-install install') }

        context 'but it has the wrong domain' do
          let(:facts) { super().merge(
            ipa: {
              domain: 'ipa.example.local'
            }
          )}
          it { is_expected.to compile.and_raise_error(/This host is already a member of domain/) }
        end
      end

      context 'with parameters from a hash' do
        let(:params) {{
          ensure: 'present',
          password: 'password',
          server: ['ipa.domain.example.local'],
          domain: 'domain.example.local',
          realm: 'DOMAIN.EXAMPLE.LOCAL',
          install_options: {
            mkhomedir: :undef,
            keytab: '/etc/krb5.keytab'
          }
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::ipa::install') }
        it { is_expected.to create_package('ipa-client') }
        expected = [
          'ipa-client-install --unattended',
          '--mkhomedir',
          '--keytab=/etc/krb5.keytab',
          '--noac',
          '--password=password',
          '--server=ipa.domain.example.local',
          '--domain=domain.example.local',
          '--realm=DOMAIN.EXAMPLE.LOCAL',
        ].join(' ')
        it { is_expected.to create_exec('ipa-client-install install').with_command(expected) }
      end

      context 'with ensure => absent' do
        let(:params) {{
          ensure: 'absent'
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_package('ipa-client') }
        it { is_expected.not_to create_exec('ipa-client-install install') }
        it { is_expected.to create_exec('ipa-client-install uninstall') \
          .with_command('ipa-client-install --unattended --uninstall') }
        it { is_expected.to create_reboot_notify('ipa-client-unstall uninstall') }
      end
    end
  end
end
