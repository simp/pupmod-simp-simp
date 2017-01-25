require 'spec_helper'

describe 'simp' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:puppet_vardir] = '/opt/puppetlabs/puppet/cache'
          facts[:server_facts] = {
            :servername => 'puppet.bar.baz',
            :serverip   => '1.2.3.4'
          }
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/opt/puppetlabs/puppet/cache/simp') }
          it { is_expected.to create_host('puppet.bar.baz').with_ip('1.2.3.4') }
          it { is_expected.to create_stunnel__connection('rsync') }
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

      end
    end
  end
end
