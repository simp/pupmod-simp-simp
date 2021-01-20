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

        if os_facts[:kernel] == 'windows'
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows .+' is not supported/) }
        else
          context 'with default parameters' do
            it_should_behave_like 'sssd client'
            if os_facts[:os][:release][:major] == '7'
              it { is_expected.to contain_sssd__domain('LOCAL')}
            else
              it { is_expected.to_not contain_sssd__domain('LOCAL')}
            end
            it { is_expected.to_not contain_sssd__domain('LDAP')}
          end

          context 'with alternate params' do
            let(:params) {{
              :ldap_domain       => true,
              :local_domain      => true,
              :autofs            => false,
              :sudo              => false,
              :ssh               => false,
              :enumerate_users   => true,
              :cache_credentials => false,
              :min_id            => 501
            }}
            it_should_behave_like 'sssd client'
            it { is_expected.to contain_sssd__domain('LOCAL').with({
              'id_provider'   => 'files',
              'min_id' => 501,
              'enumerate' => false,
              'cache_credentials' => false
              })
            }
            it { is_expected.to contain_sssd__domain('LDAP').with({
              'min_id' => 501,
              'enumerate' => true,
              'cache_credentials' => false
              })
            }
          end
        end
      end
    end
  end
end
