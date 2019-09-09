require 'spec_helper'

describe 'simp::base_services' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows' is not supported/) }
        else
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::base_apps') }
        end
      end
    end
  end
end
