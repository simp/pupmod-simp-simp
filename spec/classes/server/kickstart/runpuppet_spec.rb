require 'spec_helper'

describe 'simp::server::kickstart::runpuppet' do
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
          os_facts
        end

        context 'default parameters (using fixtures/hieradata/default.yaml)' do
          it { is_expected.to compile.with_all_deps }
          it {
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'default_runpuppet'))
            is_expected.to create_file('/var/www/ks/runpuppet').with_content(expected_content)
          }
        end

        context 'with fips=true' do
          let(:params) {{
            :fips => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/keylength\s+=\s+2048/) }
        end

        context 'specify_ntp_servers_array' do
          let(:params) {{
            :ntp_servers => ['1.2.3.4','5.6.7.8']
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/ntpdate\s+-b\s+1\.2\.3\.4\s+5\.6\.7\.8/) }
        end

        context 'specify_ntp_servers_hash' do
          let (:params) {{
            :ntp_servers => {
              '1.2.3.4' => ['foo, bar'],
              '5.6.7.8' => ['baz']
            }
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/ntpdate\s+-b\s+1\.2\.3\.4\s+5\.6\.7\.8/) }
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
