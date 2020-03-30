require 'spec_helper'

describe 'simp::base_apps' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows .+' is not supported/) }
        else
          let(:core_packages) { [
            'irqbalance',
            'netlabel_tools',
            'bind-utils'
          ] }

          context 'with default parameters' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::base_apps').with_ensure('installed') }
            it { is_expected.to contain_package('netlabel_tools').that_comes_before('Service[netlabel]') }
            it 'should install core packages' do
              core_packages.each do |package|
                is_expected.to create_package(package).with_ensure('installed')
              end
            end
            if os_facts[:os][:release][:major].to_i >= 7
              it { is_expected.to create_svckill__ignore('quotaon') }
              it { is_expected.to create_svckill__ignore('messagebus') }
            else
              it { is_expected.to create_package('hal') }
              it { is_expected.to create_package('quota') }
              it { is_expected.to create_service('haldaemon') }
              it { is_expected.to create_service('quota_nld') }
            end

            it { is_expected.to_not create_package('portreserve') }
            it { is_expected.to_not create_service('portreserve') }
          end

          context 'with portreserve configured' do
            let(:facts) {
              _facts = os_facts.dup
              _facts[:portreserve_configured] = true
              _facts
            }

            it { is_expected.to compile.with_all_deps }

            if os_facts[:os][:release][:major].to_i >= 7
              it { is_expected.to_not create_package('portreserve') }
              it { is_expected.to_not create_service('portreserve') }
            else
              it { is_expected.to create_package('portreserve') }
              it { is_expected.to create_file('/etc/portreserve/discard').with_content(/^discard$/).that_notifies('Service[portreserve]') }
              it { is_expected.to create_service('portreserve') }
            end
          end

          context 'with extra_apps' do
            let(:params) {{ :extra_apps => ['htop','git','ncdu'] }}
            let(:packages) { core_packages + ['htop','git','ncdu'] }
            it 'should install core packages with the specified extras' do
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
