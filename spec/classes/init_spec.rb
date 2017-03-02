require 'spec_helper'

describe 'simp' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:openssh_version] = '5.8'
          facts[:augeasversion] = '1.2.3'
          facts[:puppet_vardir] = '/opt/puppetlabs/puppet/cache'
          facts[:puppet_settings] = {
            'ssldir' => '/opt/puppetlabs/puppet/vardir'
          }
          facts[:server_facts] = {
            :servername => 'puppet.bar.baz',
            :serverip   => '1.2.3.4'
          }
          facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/opt/puppetlabs/puppet/cache/simp') }
        it { is_expected.to create_host('puppet.bar.baz').with_ip('1.2.3.4') }
        it { is_expected.to create_stunnel__connection('rsync') }
        it { is_expected.to_not create_filebucket('simp') }

        context 'with filebucketing' do
          context 'with local path' do
            let(:params) {{ :enable_filebucketing => true }}

            it { is_expected.to create_file('/etc/rc.d/rc.local').with_backup('simp') }
            it { is_expected.to create_filebucket('simp').with_path("#{facts[:puppet_vardir]}/simp/filebucket") }
          end

          context 'with remote server' do
            let(:params) {{
              :enable_filebucketing => true,
              :filebucket_server    => 'my.puppet.server'
            }}

            it { is_expected.to create_file('/etc/rc.d/rc.local').with_backup('simp') }
            it { is_expected.to create_filebucket('simp').with_server(params[:filebucket_server]) }
          end
        end

        context 'rsync_stunnel logic' do
          context 'with rsync_stunnel => false' do
            let(:params) {{ :rsync_stunnel => false }}
            it { is_expected.not_to create_stunnel__connection('rsync') }
          end
          context 'with rsync_stunnel => Simplib::Host' do
            let(:params) {{ :rsync_stunnel => 'other.test.host' }}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['other.test.host:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
          context 'with rsync_stunnel => true' do
            let(:params) {{ :rsync_stunnel => true }}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['1.2.3.4:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
        end

        context 'scenario' do
          scenarios = ['simp', 'simp_lite', 'poss']

          scenarios.each do |scenario|
            context scenario do
              let(:params) {{
                :scenario => scenario
              }}

              it { is_expected.to compile.with_all_deps }
              it { is_expected.to create_class("simp::scenario::#{scenario}") }
            end
          end
        end
      end
    end
  end
end
