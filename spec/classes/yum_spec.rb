require 'spec_helper'

describe 'simp::yum' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      context 'when `auto_update` is set' do
        context 'to true' do
          let(:params) { { auto_update: true } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('Simp::Yum::Schedule') }
          it { is_expected.to contain_cron('simp_yum_update').with_ensure('present')}
        end

        context 'to false' do
          let(:params) { { auto_update: false } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('Simp::Yum::Schedule') }
          it { is_expected.to contain_cron('simp_yum_update').with_ensure('absent') }
        end
      end

    end
  end
end
