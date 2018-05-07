require 'spec_helper'

describe 'simp::server::kickstart::runpuppet' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        facts = os_facts.dup
        facts[:servername] = 'my.happy.server'
        facts[:server_facts] = { :servername => 'my.happy.server' }
        facts
      end

      let(:init_sys_suffix) do
        if (os_facts[:init_systems].include?('systemd'))
           '_systemd'
        else
           ''
        end
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
            "default_runpuppet#{init_sys_suffix}"))
          is_expected.to create_file('/var/www/ks/runpuppet').with_content(expected_content)
        end
      end

      context 'with reboot_on_failure=false' do
        let(:params) {{
          :reboot_on_failure => false
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            "runpuppet_without_reboot_on_failure#{init_sys_suffix}"))
          is_expected.to create_file('/var/www/ks/runpuppet').with_content(expected_content)
        end
      end

      context 'with fips=true' do
        let(:params) {{
          :fips => true
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/var/www/ks/runpuppet').with_content(/--puppet-keylength 2048/) }
      end

      context 'ntp_servers array' do
        let(:params) {{
          :ntp_servers => ['1.2.3.4','5.6.7.8']
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            "runpuppet_with_ntp_servers#{init_sys_suffix}"))
          is_expected.to create_file('/var/www/ks/runpuppet').with_content(expected_content)
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
            "runpuppet_with_ntp_servers#{init_sys_suffix}"))
          is_expected.to create_file('/var/www/ks/runpuppet').with_content(expected_content)
        end
      end

      context 'print_stats=false' do
        let(:params) {{
          :runpuppet_print_stats => false
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            "runpuppet_without_print_stats#{init_sys_suffix}"))
          is_expected.to create_file('/var/www/ks/runpuppet').with_content(expected_content)
        end
      end

      context 'wait_for_cert=false' do
        let(:params) {{
          :runpuppet_wait_for_cert => false
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected_content = File.read(File.join(File.dirname(__FILE__), 'files',
            "runpuppet_without_wait_for_cert#{init_sys_suffix}"))
          is_expected.to create_file('/var/www/ks/runpuppet').with_content(expected_content)
        end
      end
    end
  end
end
