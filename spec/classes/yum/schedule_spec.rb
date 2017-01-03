require 'spec_helper'

describe 'simp::yum::schedule' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_cron('yum_update') }
    end
  end
end
