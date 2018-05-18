require 'spec_helper'

describe 'simp::ipa::install' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts[:ipa] = {
          domain: 'ipa.example.local',
          realm: 'EXAMPLE.LOCAL'
        }
        os_facts
      end

      context 'with ensure => present' do
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
            server: 'ipa.domain.example.local',
            ip_address: '192.168.1.5',
            domain: 'domain.example.local',
            realm: 'DOMAIN.EXAMPLE.LOCAL',
            hostname: 'client.domain.example.local',
            no_ac: false,
            force: true,
          }}
          it { is_expected.to compile.with_all_deps }
          expected = [
            'ipa-client-install --unattended',
            '--force',
            '--password=password',
            '--server=ipa.domain.example.local',
            '--ip-address=192.168.1.5',
            '--domain=domain.example.local',
            '--realm=DOMAIN.EXAMPLE.LOCAL',
            '--hostname=client.domain.example.local'
          ].join(' ')
          it { is_expected.to create_exec('ipa-client-install install').with_command(expected) }
        end

        context 'each $enroll setting' do
          context '$enroll => auto and the domain from the ipa fact matches the configured domain' do
            let(:params) {{
              ensure: 'present',
              domain: 'ipa.example.local',
              realm: 'EXAMPLE.LOCAL',
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.not_to create_exec('ipa-client-install install') }
            it { is_expected.not_to create_exec('ipa-client-install uninstall') }
          end
          context '$enroll => force' do
            let(:params) {{
              ensure: 'present',
              enroll: 'force',
              domain: 'domain.example.local',
              realm: 'DOMAIN.EXAMPLE.LOCAL',
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_exec('ipa-client-install install') }
            it { is_expected.not_to create_exec('ipa-client-install uninstall') }
          end
          context '$enroll => no' do
            let(:params) {{
              ensure: 'present',
              enroll: 'no',
              domain: 'domain.example.local',
              realm: 'DOMAIN.EXAMPLE.LOCAL',
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.not_to create_exec('ipa-client-install install') }
            it { is_expected.not_to create_exec('ipa-client-install uninstall') }
          end
        end

        context 'with parameters from a hash' do
          let(:params) {{
            ensure: 'present',
            password: 'password',
            server: 'ipa.domain.example.local',
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
      end

      context 'with ensure => absent' do
        let(:params) {{
          ensure: 'absent'
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_package('ipa-client') }
        it { is_expected.not_to create_exec('ipa-client-install install') }
        it { is_expected.to create_exec('ipa-client-install uninstall') \
          .with_command('ipa-client-install --uninstall --unattended') }
        it { is_expected.to create_reboot_notify('ipa-client-unstall uninstall') }
      end
    end
  end
end
