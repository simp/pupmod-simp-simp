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

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('simp::puppetdb') }
          it { is_expected.to contain_class('puppetdb').with(
            :listen_address                    => '127.0.0.1',
            :listen_port                       => 8138,
            :open_listen_port                  => false,
            :ssl_deploy_certs                  => true,
            :ssl_set_cert_paths                => true,
            :ssl_listen_address                => '0.0.0.0',
            :ssl_listen_port                   => 8139,
            :disable_ssl                       => false,
            :manage_package_repo               => false,
#            :database_password      => varies from run-to-run
            :read_database_username            => 'simp_puppetdb',
#            :read_database_password => varies from run-to-run
            :read_database_name                => 'simp_puppetdb',
            :read_database_jdbc_ssl_properties => '?ssl=true',
            :manage_firewall                   => false,
#            :java_args              => Xmx & Xms vary because of OS memory differences in facts
          ) }
          it { is_expected.to contain_class('puppetdb::master::config') }
          it {
            is_expected.to contain_file("#{Puppet[:confdir]}/puppetdb.conf").with( {
              :owner => 'root',
              :group => 'root',
              :mode  => '0644'
            } )
          }
        end

        context 'with read_database_ssl = true' do
          let(:hieradata) { 'simp__puppetdb' }
          let(:params) {{ :read_database_ssl => true }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('puppetdb').with_read_database_jdbc_ssl_properties('?ssl=true') }
        end

        context 'with read_database_ssl = false' do
          let(:hieradata) { 'simp__puppetdb' }
          let(:params) {{ :read_database_ssl => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('puppetdb').with_read_database_jdbc_ssl_properties('') }
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
