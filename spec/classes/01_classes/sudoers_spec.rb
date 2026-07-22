require 'spec_helper'

describe 'simp::sudoers' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
        else
          context 'with default parameters' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::sudoers') }
            it { is_expected.to create_class('sudo') }
            it { is_expected.to contain_sudo__default_entry('00_main') }
            it { is_expected.not_to create_class('::simp::sudoers::aliases') }
          end

          context 'with common_aliases => false' do
            let(:params) { { common_aliases: false } }

            it { is_expected.to contain_sudo__default_entry('00_main') }
            it { is_expected.not_to create_class('::simp::sudoers::aliases') }
          end
        end
      end
    end
  end
end
