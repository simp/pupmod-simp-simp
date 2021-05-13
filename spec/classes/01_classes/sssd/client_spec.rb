require 'spec_helper'

shared_examples_for 'sssd client' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_class('sssd') }
end

describe 'simp::sssd::client' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:params) {{ :ldap_server_type => 'plain' }}

        if os_facts[:kernel] == 'windows'
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows .+' is not supported/) }
        else
          context 'with default parameters' do
            it_should_behave_like 'sssd client'
            if os_facts[:os][:release][:major] < '8'
              it { is_expected.to contain_sssd__domain('LOCAL')}
            else
              it { is_expected.to_not contain_sssd__domain('LOCAL')}
            end
            it { is_expected.to_not contain_sssd__domain('LDAP')}
          end

          context 'with alternate params' do
            let(:params) {{
              :local_domain          => true,
              :local_domain_options  => { 'max_id' => 12345 },
              :ldap_domain           => true,
              :ldap_domain_options   => { 'max_id' => 23456 },
              :ldap_provider_options => { 'ldap_user_name' => 'bob' },
              :ldap_server_type      => '389ds',
              :enumerate_users       => true,
              :cache_credentials     => false,
              :min_id                => 501
            }}

            it_should_behave_like 'sssd client'
            it {
              is_expected.to contain_sssd__domain('LOCAL')
                .with_id_provider('files')
                .with_min_id(501)
                .with_max_id(12345)
                .with_enumerate(false)
                .with_cache_credentials(false)
            }

            it {
              is_expected.to contain_sssd__domain('LDAP')
                .with_id_provider('ldap')
                .with_min_id(501)
                .with_max_id(23456)
                .with_enumerate(true)
                .with_cache_credentials(false)
            }

            it {
              is_expected.to contain_sssd__provider__ldap('LDAP')
                .with_ldap_account_expire_policy('ipa')
                .with_ldap_user_ssh_public_key('nsSshPublicKey')
            }
          end
        end
      end
    end
  end
end
