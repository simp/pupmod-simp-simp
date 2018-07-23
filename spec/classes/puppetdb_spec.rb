require 'spec_helper'

describe 'simp::puppetdb' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          { :puppet_settings => { 'main' => { 'hostprivkey' => 'blah' } }}.merge(os_facts)
        end
        context 'with default parameters' do
          let(:hieradata) { 'simp__puppetdb' }
          # Overriding the file definition for puppetdb::ssl_cert/key/ca to use
          # undef for content results in:
          # Could not understand source file://: bad URI(absolute but no path)
          pending('is_expected.to compile.with_all_deps')
        end

        context 'with use_puppet_ssl_certs => false' do
          let(:hieradata) { 'simp__puppetdb' }
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
          it {
            is_expected.to contain_file("#{Puppet[:confdir]}/puppetdb.conf").with( {
              :owner => 'root',
              :group => 'root',
              :mode  => '0644'
            } )
          }
          it { is_expected.to contain_class('puppetdb::master::puppetdb_conf').that_notifies('Class[pupmod::master::base]') }
        end

        context 'with use_puppet_ssl_certs => false and manage_puppetserver => false' do
          let(:hieradata) { 'simp__puppetdb' }
          let(:params) do
          {
            :use_puppet_ssl_certs => false,
            :manage_puppetserver => false
          }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('puppetdb::master::puppetdb_conf') }
          it { is_expected.to_not contain_class('puppetdb::master::puppetdb_conf').that_notifies('Class[pupmod::master::base]') }
          it { is_expected.to_not contain_class('pupmod::master::base') }
        end

        context 'with puppetdb::master::config::manage_config: false' do
          let(:hieradata) { 'simp_puppetdb_manage_config_false' }
          let(:params) do
          {
            :use_puppet_ssl_certs => false
          }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not contain_file("#{Puppet[:confdir]}/puppetdb.conf") }
          it { is_expected.to_not contain_class('pupmod::master::base') }
        end
      end
    end
  end
end
