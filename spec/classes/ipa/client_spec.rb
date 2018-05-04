require 'spec_helper'

describe 'simp::ipa::client' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::ipa::client') }
        it { is_expected.not_to create_pam__access__rule('Allow posixusers') }
      end

      context 'with $pam enabled' do
        let(:params) {{
          pam: true
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_pam__access__rule('Allow posixusers').with(
          users: ['(posixusers)'],
          origins: ['1.2.3.4/24','5.6.7.8/16']
        ) }
      end
    end
  end
end
