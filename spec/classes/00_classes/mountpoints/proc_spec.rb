require 'spec_helper'

describe 'simp::mountpoints::proc' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
        else
          it {
            is_expected.to create_group('simp_proc_read')
              .with_ensure('present')
              .with_allowdupe(false)
              .with_forcelocal(true)
              .with_gid(231)
              .that_notifies('Mount[/proc]')
          }
          it { is_expected.to create_mount('/proc').with_options('hidepid=2,gid=231') }

          context 'with manage_proc_group = false' do
            let(:params) do
              {
                manage_proc_group: false,
              }
            end

            it { is_expected.not_to create_group('simp_proc_read') }
            it { is_expected.to create_mount('/proc').with_options('hidepid=2,gid=231') }
          end

          context 'with proc_gid = 0' do
            let(:params) do
              {
                proc_gid: 0,
              }
            end

            it { is_expected.not_to create_group('simp_proc_read') }
            it { is_expected.to create_mount('/proc').with_options('hidepid=2') }
          end
        end
      end
    end
  end
end
