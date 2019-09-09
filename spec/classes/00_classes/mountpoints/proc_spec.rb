require 'spec_helper'

describe 'simp::mountpoints::proc' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows' is not supported/) }
        else
          context 'with default parameters' do
            it { is_expected.to create_mount('/proc').with_options('hidepid=2') }
          end

          context 'with proc_gid specified' do
            let(:params) {{ :proc_gid => 100 }}
            it { is_expected.to create_mount('/proc').with_options('hidepid=2,gid=100') }
          end
        end
      end
    end
  end
end
