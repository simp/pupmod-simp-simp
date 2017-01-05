require 'spec_helper'

describe 'simp::mcollective' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) {
        facts[:puppetversion] = %x{puppet --version}.strip
        facts[:mco_version] = '2.9.1'
        facts
      }

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::mcollective') }
        it { is_expected.to create_class('mcollective') }
        it { is_expected.to create_class('activemq') }
      end
    end
  end
end
