require 'spec_helper'

describe 'simp::admin' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts['puppet_settings'] = {
            'ssldir' => '/opt/puppet/somewhere/ssl'
          }

          facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_sudo__alias__user('admins') }
        it { is_expected.to create_sudo__alias__user('auditors') }
      end
    end
  end
end
