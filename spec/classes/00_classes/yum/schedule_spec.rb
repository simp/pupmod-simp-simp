require 'spec_helper'

describe 'simp::yum::schedule' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      if os_facts[:kernel] == 'windows'
        it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
      else
        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_cron('simp_yum_update') }
        end
      end
    end
  end
end
