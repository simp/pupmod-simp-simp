require 'spec_helper'

describe 'simp::sudoers::aliases' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts){ os_facts }

      let(:cmnd_list) {[
        'audit',
        'delegating',
        'drivers',
        'locate',
        'networking',
        'processes',
        'services',
        'selinux',
        'software',
        'storage',
        'su'
      ]}

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('simp::sudoers::aliases') }

      context 'default parameters' do
        it 'creates sudo::alias::cmnd for each alias' do
          cmnd_list.each do |cmnd|
            is_expected.to contain_sudo__alias__cmnd(cmnd)
          end
        end
      end

    end
  end
end
