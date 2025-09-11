require 'spec_helper'

describe 'simp::prelink' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      if os_facts[:kernel] == 'windows'
        let(:facts) { os_facts }
        it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
      else
        context 'with default parameters' do
          context 'when prelink is not installed' do
            let(:facts) do
              os_facts.merge(
                prelink: nil,
              )
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::prelink') }
            it { is_expected.not_to contain_package('prelink') }
          end

          context 'when prelink is installed and disabled' do
            let(:facts) do
              os_facts.merge(
                prelink: { enabled: false },
              )
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::prelink') }
            it {
              is_expected.to contain_exec('remove prelinking').with(
                command: '/etc/cron.daily/prelink',
                before: 'Package[prelink]',
              )
            }

            it { is_expected.to contain_package('prelink').with_ensure('absent') }
          end

          context 'when prelink is installed and enabled' do
            let(:facts) do
              os_facts.merge(
                prelink: { enabled: true },
                # if prelink is on, FIPS cannot be enabled, because the
                # system would be broken in that configuration
                fips_enabled: false,
              )
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::prelink') }
            it {
              is_expected.to contain_augeas('disable prelink').with(
                lens: 'Shellvars.lns',
                incl: '/etc/sysconfig/prelink',
                changes: [
                  'set PRELINKING "no"',
                ],
                before: 'Exec[remove prelinking]',
              )
            }

            it {
              is_expected.to contain_exec('remove prelinking').with(
                command: '/etc/cron.daily/prelink',
                before: 'Package[prelink]',
              )
            }

            it { is_expected.to contain_package('prelink').with_ensure('absent') }
          end
        end

        context 'when enable=true' do
          context 'when FIPS mode is not enabled' do
            let(:facts) do
              os_facts.merge(fips_enabled: false)
            end

            let(:params) { { enable: true } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::prelink') }
            it {
              is_expected.to contain_augeas('enable prelink').with(
                lens: 'Shellvars.lns',
                incl: '/etc/sysconfig/prelink',
                changes: [
                  'set PRELINKING "yes"',
                ],
                subscribe: 'Package[prelink]',
              )
            }
          end

          context 'when FIPS mode is enabled and prelink is installed' do
            let(:facts) do
              os_facts.merge(
                prelink: { enabled: false },
                fips_enabled: true,
              )
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::prelink') }
            it {
              is_expected.to contain_exec('remove prelinking').with(
                command: '/etc/cron.daily/prelink',
                before: 'Package[prelink]',
              )
            }

            it { is_expected.to contain_package('prelink').with_ensure('absent') }
          end
        end
      end
    end
  end
end
