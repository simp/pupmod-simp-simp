require 'spec_helper'

describe 'simp::server::ldap' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows .+' is not supported/) }
        else
          context 'default parameters' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp_openldap') }
            it { is_expected.to create_class('simp_openldap::server') }
            it { is_expected.to create_class('simp_openldap::slapo::ppolicy') }
            it { is_expected.to create_class('simp_openldap::slapo::syncprov') }
            it { is_expected.to_not create_simp_openldap__server__syncrepl('111') }
            it { is_expected.to create_simp_openldap__server__limits('Host_Bind_DN_Unlimited_Query') }
            it { is_expected.to create_simp_openldap__server__limits('LDAP_Sync_DN_Unlimited_Query') }
          end

          context 'is_slave' do
            let(:params){{ :is_slave => true }}

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_simp_openldap__server__syncrepl('111') }
          end

          context 'use_lastbind' do
            let(:params){{ :enable_lastbind => true }}

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp_openldap::slapo::lastbind') }
          end
        end
      end
    end
  end
end
