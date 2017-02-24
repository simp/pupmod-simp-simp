require 'spec_helper'

describe 'simp::yum::schedule' do
  on_supported_os.each do |os, facts|
    let(:facts) do
      facts
    end

    context 'with default parameters' do
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_cron('simp_yum_update') }
    end
  end
end
