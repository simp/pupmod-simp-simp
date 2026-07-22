require 'spec_helper'

describe 'simp::base_apps' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
        else
          let(:core_packages) do
            [
              'irqbalance',
              'netlabel_tools',
              'bind-utils',
            ]
          end

          context 'with default parameters' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::base_apps').with_ensure('installed') }
            it { is_expected.to contain_package('netlabel_tools').that_comes_before('Service[netlabel]') }
            it 'installs core packages' do
              core_packages.each do |package|
                is_expected.to create_package(package).with_ensure('installed')
              end
            end

            it { is_expected.to create_svckill__ignore('quotaon') }
            it { is_expected.to create_svckill__ignore('messagebus') }
          end

          context 'with extra_apps' do
            let(:params) { { extra_apps: ['htop', 'git', 'ncdu'] } }
            let(:packages) { core_packages + ['htop', 'git', 'ncdu'] }

            it 'installs core packages with the specified extras' do
              packages.each do |package|
                is_expected.to create_package(package).with_ensure('installed')
              end
            end
          end
        end
      end
    end
  end
end
