require 'spec_helper'

describe 'simp::server::kickstart::simp_client_bootstrap' do
  def server_facts_hash
    return {
      'serverversion' => Puppet.version,
      'servername'    => 'puppet.bar.baz',
      'serverip'      => '1.2.3.4'
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      context 'default parameters (using fixtures/hieradata/default.yaml)' do
        it { is_expected.to compile.with_all_deps }
        it do
           expected_content = File.read(File.join(File.dirname(__FILE__),
             '..', '..', '..', '..', 'files', 'var', 'www', 'ks',
             'bootstrap_simp_client'))

          is_expected.to create_file('/var/www/ks/bootstrap_simp_client').with({
            :ensure  => 'file',
            :owner   => 'root',
            :group   => 'apache',
            :mode    => '0640',
            :content => expected_content
          })
        end

        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'default_simp_client_bootstrap'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap').with_content(expected_content)
        end

        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'default_simp_client_bootstrap.service'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap.service').with_content(expected_content)
        end
      end

      context 'with reboot_on_failure=false' do
        let(:params) {{
          :reboot_on_failure => false
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_without_reboot_on_failure'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap').with_content(expected_content)
        end

        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_without_reboot_on_failure.service'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap.service').with_content(expected_content)
        end
      end

      context 'with fips=true' do
        let(:params) {{
          :fips => true
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/var/www/ks/simp_client_bootstrap').with_content(/--puppet-keylength 2048/) }
        it { is_expected.to create_file('/var/www/ks/simp_client_bootstrap.service').with_content(/--puppet-keylength 2048/) }
      end

      context 'ntp_servers array' do
        let(:params) {{
          :ntp_servers => ['1.2.3.4','5.6.7.8']
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_with_ntp_servers'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap').with_content(expected_content)
        end

        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_with_ntp_servers.service'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap.service').with_content(expected_content)
        end
      end

      context 'ntp_servers hash' do
        let (:params) {{
          :ntp_servers => {
            '1.2.3.4' => ['foo, bar'],
            '5.6.7.8' => ['baz']
          }
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_with_ntp_servers'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap').with_content(expected_content)
        end

        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_with_ntp_servers.service'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap.service').with_content(expected_content)
        end
      end

      context 'print_stats=false' do
        let(:params) {{
          :puppet_print_stats => false
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_without_print_stats'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap').with_content(expected_content)
        end

        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_without_print_stats.service'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap.service').with_content(expected_content)
        end
      end

      context 'wait_for_cert=false' do
        let(:params) {{
          :puppet_wait_for_cert => false
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_without_wait_for_cert'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap').with_content(expected_content)
        end

        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            'simp_client_bootstrap_without_wait_for_cert.service'))
          is_expected.to create_file('/var/www/ks/simp_client_bootstrap.service').with_content(expected_content)
        end
      end
    end
  end
end
