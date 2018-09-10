# Can't run this until lwe get access to server_facts
require 'spec_helper'

describe 'simp::server::kickstart' do
  def server_facts_hash
    return {
      'serverversion' => Puppet.version,
      'servername'    => 'puppet.bar.baz',
      'serverip'      => '1.2.3.4'
    }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts[:puppet_settings] = {
            :agent => {
              :server    => server_facts_hash['servername'],
              :ca_server => server_facts_hash['servername']
            }
          }

          os_facts
        end

        context 'default settings' do
          let(:params) {{ :data_dir => '/var/www' }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('dhcp::dhcpd') }
          it { is_expected.to create_class('tftpboot') }
          it { is_expected.to create_simp_apache__site('ks').with_content(/Allow from 1.2.3.4\/24/) }
          it { is_expected.to create_file('/var/www/ks').with_mode('2640') }
          it { is_expected.to contain_class('simp::server::kickstart::runpuppet') }
          it { is_expected.to contain_class('simp::server::kickstart::simp_client_bootstrap') }
        end

        context 'manage_dhcp = false' do
          let(:params) {{ :manage_dhcp => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not create_class('dhcp::dhcpd') }
        end

        context 'manage_tftpboot = false' do
          let(:params) {{ :manage_tftpboot => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not create_class('tftpboot') }
        end

        context 'manage_runpuppet = false' do
          let(:params) {{ :manage_runpuppet => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not contain_class('simp::server::kickstart::runpuppet') }
        end

        context 'manage_simp_client_bootstrap = false' do
          let(:params) {{ :manage_simp_client_bootstrap => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not contain_class('simp::server::kickstart::simp_client_bootstrap') }
        end

        context 'alternate_data_dir' do
          let(:params) {{ :data_dir => '/srv/www' }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/www/ks').with_target('/srv/www/ks') }
        end
      end
    end
  end
end
