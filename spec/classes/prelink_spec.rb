require 'spec_helper'

describe 'simp::prelink' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      context 'with default parameters' do
        context 'when prelink is not installed' do
          let(:facts) do
            os_facts
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::prelink') }
          it { is_expected.to_not contain_package('prelink') }
        end

        context 'when prelink is installed and disabled' do
          let(:facts) do
            os_facts.merge( {:prelink => { :enabled => false } } )
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::prelink') }
          it {
            is_expected.to contain_exec('remove prelinking').with( {
              :command     => '/etc/cron.daily/prelink',
              :before      =>'Package[prelink]'
            } )
          }

          it { is_expected.to contain_package('prelink').with_ensure('absent') }
        end

        context 'when prelink is installed and enabled' do
          let(:facts) do
            os_facts.merge( {:prelink => { :enabled => true } } )
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::prelink') }
          it {
            is_expected.to contain_shellvar('disable prelink').with( {
              :ensure   => 'present',
              :target   => '/etc/sysconfig/prelink',
              :variable => 'PRELINKING',
              :value    => 'no',
              :before   => 'Exec[remove prelinking]'
            } )
          }

          it {
            is_expected.to contain_exec('remove prelinking').with( {
              :command     => '/etc/cron.daily/prelink',
              :before      =>'Package[prelink]'
            } )
          }

          it { is_expected.to contain_package('prelink').with_ensure('absent') }
        end

      end

      context 'when enable=true' do
        let(:facts) do
          os_facts
        end

        let(:params) {{ :enable => true }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::prelink') }
        it { is_expected.to contain_package('prelink').that_comes_before('Shellvar[enable prelink]') }
        it {
          is_expected.to contain_shellvar('enable prelink').with( {
            :ensure   => 'present',
            :target   => '/etc/sysconfig/prelink',
            :variable => 'PRELINKING',
            :value    => 'yes'
          } )
         }
      end
    end
  end
end
