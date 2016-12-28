require 'spec_helper'

describe 'simp::root_user' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts){ os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('simp::root_user') }

      it 'manages root user by default' do
        is_expected.to create_file('/root')
        is_expected.to create_user('root')
        is_expected.to create_group('root')
      end

      context 'unless told not to' do
        let(:params) {{
          :manage_perms => false,
          :manage_user  => false,
          :manage_group => false
        }}
        it {
          is_expected.not_to create_file('/root')
          is_expected.not_to create_user('root')
          is_expected.not_to create_group('root')
        }
      end

    end
  end
end
