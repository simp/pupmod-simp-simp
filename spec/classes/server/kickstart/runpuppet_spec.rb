require 'spec_helper'

describe 'simp::server::kickstart::runpuppet' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:servername] = 'my.happy.server'
          facts[:server_facts] = { :servername => 'my.happy.server' }
          facts
        end

        context 'specify_ntp_servers_array' do
          let(:params) {{
            :ntp_servers => ['1.2.3.4','5.6.7.8']
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/ntpdate -b 1.2.3.4 5.6.7.8/) }
        end

        context 'specify_ntp_servers_hash' do
          let (:params) {{
            :ntp_servers => {
              '1.2.3.4' => ['foo, bar'],
              '5.6.7.8' => ['baz']
            }
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/ntpdate -b 1.2.3.4 5.6.7.8/) }
        end

        context 'no_print_stats' do
          let(:params) {{
            :runpuppet_print_stats => false
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to create_file('/var/www/ks/runpuppet').with_content(/--evaltrace/) }
        end

        context 'no_wait_for_cert' do
          let(:params) {{
            :runpuppet_wait_for_cert => false
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to create_file('/var/www/ks/runpuppet').with_content(/--waitforcert/) }
        end


      end
    end
  end
end
