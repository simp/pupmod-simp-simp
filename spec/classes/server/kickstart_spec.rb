# Can't run this until lwe get access to server_facts
require 'spec_helper'

describe 'simp::server::kickstart' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:puppet_settings] = {
            :agent => {
              :server    => 'my.happy.server',
              :ca_server => 'my.happy.server'
            }
          }
          # This is to replace the Puppet server provided $::servername variable.
          # In the future, this should move to using the $server_facts hash.
          facts[:servername] = 'my.happy.server'
          facts[:server_facts] = { :servername => 'my.happy.server' }
          facts
        end

        let(:params) {{ :data_dir => '/var/www' }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_apache') }
        it { is_expected.to create_class('dhcp::dhcpd') }
        it { is_expected.to create_class('tftpboot') }
        it { is_expected.to create_simp_apache__site('ks').with_content(/Allow from 1.2.3.4\/24/) }
        it { is_expected.to create_file('/var/www/ks').with_mode('2640') }
        it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/puppet=.*--waitforcert 10.*--evaltrace --summarize/) }
        it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/puppet_server=\"puppet.bar.baz\"/) }
        it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/ca_server = puppet.bar.baz/) }
        it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/ca_port = 8141/) }
        it { is_expected.not_to create_file('/var/www/ks/runpuppet').with_content(/ntpdate/) }

        context 'alternate_data_dir' do
          let(:params) {{ :data_dir => '/srv/www' }}
          it { is_expected.to create_file('/var/www/ks').with_target('/srv/www/ks') }
        end
      end
    end
  end
end
