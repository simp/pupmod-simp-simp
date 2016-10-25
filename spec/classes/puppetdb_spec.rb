require 'spec_helper'

describe 'simp::puppetdb' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge(:puppet_settings => { 'main' => { 'hostprivkey' => 'blah' } })
        end
        context 'with default parameters' do
          # Overriding the file definition for puppetdb::ssl_cert/key/ca to use
          # undef for content results in:
          # Could not understand source file://: bad URI(absolute but no path)
          pending('is_expected.to compile.with_all_deps')
        end

        context 'with use_puppet_ssl_certs => false' do
          let(:params) do
          {
            :use_puppet_ssl_certs => false
          }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('simp::puppetdb') }
          it { is_expected.to contain_class('puppetdb::master::config') }
          it { is_expected.to contain_class('pupmod::master::base') }
          it { is_expected.to contain_class('puppetdb::master::puppetdb_conf') }
          # This won't work for some reason.
          pending("it { is_expected.to contain_class('puppetdb::master::puppetdb_conf').that_comes_before('Class[::pupmod::master::base]') }")
        end

        context 'with use_puppet_ssl_certs => false and manage_puppetserver => false' do
          let(:params) do
          {
            :use_puppet_ssl_certs => false,
            :manage_puppetserver => false
          }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not contain_class('pupmod::master::base') }
          it { is_expected.to_not contain_class('puppetdb::master::puppetdb_conf').that_comes_before('Class[::pupmod::master::base]') }
        end
      end
    end
  end
end
