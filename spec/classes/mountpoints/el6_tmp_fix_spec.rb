require 'spec_helper'

describe 'simp::mountpoints::el6_tmp_fix' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:selinux_mode] = 'disabled'
          facts
        end

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
