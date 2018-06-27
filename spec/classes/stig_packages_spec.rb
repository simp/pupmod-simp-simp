
require 'spec_helper'

describe 'simp::stig_packages' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::stig_packages') }
          it { is_expected.to create_class('simp::stig_packages::ensure_installed').with_stage('simp_finalize') }
          it { is_expected.to create_class('simp::stig_packages::ensure_absent').with_stage('simp_finalize') }
        end

      end
    end
  end
end
