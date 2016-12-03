require 'spec_helper'

describe 'simp::ftpusers' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts){ os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('simp::ftpusers') }

      context 'with default parameters' do
        it { is_expected.to create_file('/etc/ftpusers') }
        it { is_expected.to create_ftpusers('/etc/ftpusers').with({
          :min_id => '500'
        }) }
      end

      context 'with min_uid set to an empty string' do
        let(:params) {{ :min_uid => '' }}
        it { is_expected.not_to create_file('/etc/ftpusers') }
        it { is_expected.not_to create_ftpusers('/etc/ftpusers') }
      end

    end
  end
end