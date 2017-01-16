require 'spec_helper'

describe 'simp::server' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.not_to create_pam__access__rule('allow_simp') }
          it { is_expected.not_to create_sudo__user_specification('default_simp') }
        end

        context 'with allow_simp_user => true' do
          let(:params){{
            :pam => true,
            :allow_simp_user => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to create_pam__access__rule('allow_simp') }
          it { is_expected.to create_sudo__user_specification('default_simp') }
        end

      end
    end
  end
end
