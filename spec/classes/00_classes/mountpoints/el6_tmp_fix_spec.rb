require 'spec_helper'

describe 'simp::mountpoints::el6_tmp_fix' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows' is not supported/) }
        else
          context 'with default parameters' do
            it { is_expected.to create_upstart__job('fix_tmp_perms').with({
              :main_process_type => 'script',
              :start_on => 'runlevel [0123456]',
            }) }
          end
        end
      end
    end
  end
end
