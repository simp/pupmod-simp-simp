require 'spec_helper'

describe 'simp::pam_limits::stack_clash' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_pam__limits__rule('ignore_stack')}
        it { is_expected.to contain_pam__limits__rule('ignore_as')}
        it { is_expected.to contain_pam__limits__rule('limit_stack')}
        it { is_expected.to contain_pam__limits__rule('limit_as')}
      end
    end
  end
end
