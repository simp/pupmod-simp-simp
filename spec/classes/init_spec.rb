require 'spec_helper'

describe 'simp' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        let(:server_facts) do
          @server_facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file("#{facts[:puppet_vardir]}/simp") }

=begin
## Can't test this until we can set the 'server_facts' in rspec-puppet
        context 'rsync_stunnel logic' do
          context 'with rsync_stunnel defined' do
            let(:params) {{ :rsync_stunnel => 'puppet.bar.baz' }}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['puppet.bar.baz:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
          context 'without rsync_stunnel and with servername' do
            let(:facts) { facts.merge({ :serverip => '1.2.3.4' })}
            let(:params) {{ :rsync_stunnel => false }}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['1.2.3.4:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
          context 'with neither enabled' do
            let(:facts) { facts }
            let(:params) {{ :rsync_stunnel => false }}
            it { is_expected.not_to create_stunnel__connection('rsync') }
          end
        end
=end

      end
    end
  end
end
