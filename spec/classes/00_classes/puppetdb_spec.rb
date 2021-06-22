require 'spec_helper'

describe 'simp::puppetdb' do
  fips_mode_save = OpenSSL.fips_mode

  before(:each) do
    OpenSSL.fips_mode = false if OpenSSL.respond_to?(:fips_mode)
  end

  after(:each) do
    OpenSSL.fips_mode = fips_mode_save if OpenSSL.respond_to?(:fips_mode)
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        if os_facts[:kernel] == 'windows'
          let(:facts) { os_facts }
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows .+' is not supported/) }
        else
          let(:facts) do
            { :puppet_settings => { 'main' => { 'hostprivkey' => 'blah' } }}.merge(os_facts)
          end

          if os_facts[:os][:release][:major] == '7'
           expected_ciphers = [
            'TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDH_RSA_WITH_AES_256_CBC_SHA',
            'TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDH_RSA_WITH_AES_128_CBC_SHA',
            'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA',
            'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA',
            'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA',
            'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA',
            'TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA',
            'TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA',
            'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_DHE_RSA_WITH_AES_256_CBC_SHA256',
            'TLS_DHE_RSA_WITH_AES_256_CBC_SHA',
            'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_DHE_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_DHE_RSA_WITH_AES_128_CBC_SHA',
            'TLS_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_RSA_WITH_AES_256_CBC_SHA256',
            'TLS_RSA_WITH_AES_256_CBC_SHA',
            'TLS_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_RSA_WITH_AES_128_CBC_SHA',
            'TLS_DHE_DSS_WITH_AES_256_GCM_SHA384',
            'TLS_DHE_DSS_WITH_AES_256_CBC_SHA256',
            'TLS_DHE_DSS_WITH_AES_256_CBC_SHA',
            'TLS_DHE_DSS_WITH_AES_128_GCM_SHA256',
            'TLS_DHE_DSS_WITH_AES_128_CBC_SHA256',
            'TLS_DHE_DSS_WITH_AES_128_CBC_SHA',
            'TLS_EMPTY_RENEGOTIATION_INFO_SCSV'
           ].join(',')
          else
           expected_ciphers = [
            'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA',
            'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA',
            'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA',
            'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA',
            'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_DHE_RSA_WITH_AES_256_CBC_SHA256',
            'TLS_DHE_RSA_WITH_AES_256_CBC_SHA',
            'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_DHE_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_DHE_RSA_WITH_AES_128_CBC_SHA',
            'TLS_EMPTY_RENEGOTIATION_INFO_SCSV'
           ].join(',')
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
              :cipher_suites                     => expected_ciphers,
              :disable_ssl                       => false,
              :manage_package_repo               => false,
  #            :database_password      => varies from run-to-run
              :read_database_username            => 'simp_puppetdb',
  #            :read_database_password => varies from run-to-run
              :read_database_name                => 'simp_puppetdb',
              :read_database_jdbc_ssl_properties => '?ssl=true',
              :manage_firewall                   => false,
  #            :java_args              => Xmx & Xms vary because of OS memory differences in facts
              :automatic_dlo_cleanup             => true,
              :disable_update_checking           => true,
              :dlo_max_age                       => 90
            ) }

            unless os_facts[:systemd]
              it { is_expected.to contain_cron__user('puppetdb') }
            end

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
end
