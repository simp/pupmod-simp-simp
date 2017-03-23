require 'spec_helper'

describe 'simp::yum' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to_not contain_yumrepo('simp') }

      context 'when `enable_simp_internet_repos` is set' do
        context 'when `simp_version` is valid' do
          let(:params) {{
            :enable_simp_internet_repos => true,
            :simp_version               => '6.0.0-foobar'
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_yumrepo('simp-project_6_X') }
          it { is_expected.to contain_yumrepo('simp-project_6_X_Dependencies') }
        end

        context 'when `simp_version` is invalid' do
          invalid_versions = [
            '60.0.0-foo',
            'unknown',
            'blah'
          ]

          invalid_versions.each do |version|
            context "with version #{version}" do
              let(:params) {{
                :enable_simp_internet_repos => true,
                :simp_version               => version
              }}

              it {
                expect {
                  is_expected.to compile.with_all_deps
                }.to raise_error(/SIMP version .* is not supported/)
              }
            end
          end
        end
      end

      context 'when `enable_simp_local_repos` is set' do
        context 'to true' do
          let(:params) {{
            :enable_simp_local_repos => true,
            :servers                 => ['yum.bar.baz']
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_yumrepo('simp').with_enabled('1') }

          it 'creates the SIMP Yumrepo' do
            is_expected.to contain_yumrepo('simp').with(
              gpgkey:  %r{^https://yum.bar.baz/yum/SIMP},
              baseurl: %r{^https://yum.bar.baz/yum/SIMP}
            )
          end

          if (facts[:os][:release][:major].to_s == '6') && (facts[:os][:name] == 'CentOS')
            it 'creates the OS Updates Yumrepo' do
              is_expected.to contain_yumrepo('os_updates').with(
                gpgkey: %r{^https://yum.bar.baz/yum/CentOS/6/x86_64/RPM-GPG-KEY-CentOS-6},
                baseurl: %r{^https://yum.bar.baz/yum/CentOS/6/x86_64/Updates}
              )
            end
          else
            it 'creates the OS Update Yumrepo' do
              is_expected.to contain_yumrepo('os_updates')
            end
          end
        end
      end

      context 'when `enable_os_repos` is set' do
        context 'to true' do
          let(:params) {{
            :enable_simp_local_repos => true,
            :enable_os_repos         => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_yumrepo('os_updates').with_enabled('1') }
        end

        context 'to false' do
          let(:params) {{
            :enable_simp_local_repos => true,
            :enable_os_repos         => false
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_yumrepo('os_updates').with_enabled('0') }
        end
      end

      context 'when `enable_auto_updates` is set' do
        context 'to true' do
          let(:params) { { enable_auto_updates: true } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('Simp::Yum::Schedule') }
          it { is_expected.to contain_cron('simp_yum_update').with_ensure('present')}
        end

        context 'to false' do
          let(:params) { { enable_auto_updates: false } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('Simp::Yum::Schedule') }
          it { is_expected.to contain_cron('simp_yum_update').with_ensure('absent') }
        end
      end

      context 'when `servers` is set' do
        netlists = [
          { desc: 'an empty netlist', list: [] },
          { desc: 'a single-element netlist', list: ['simp.test'] },
          { desc: 'a multi-element netlist', list: ['simp.test', 'example.org', '192.0.2.5'] }
        ]

        netlists.each do |netlist|
          context "to #{netlist[:desc]}" do
            base_params = {
              :enable_simp_local_repos => true,
              :servers                 => netlist[:list]
            }

            context 'and `os_update_url` is set' do
              context 'to a valid string' do
                let(:params) { base_params.merge(os_update_url: 'https://YUM_SERVER/os/updates/') }

                it { is_expected.to compile.with_all_deps }
                it 'contains Yumrepo[os_updates]' do
                  case netlist[:desc]
                  when 'an empty netlist'
                    is_expected.to contain_yumrepo('os_updates').with_baseurl('')
                  when 'a single-element netlist'
                    is_expected.to contain_yumrepo('os_updates').with_baseurl('https://simp.test/os/updates/')
                  when 'a multi-element netlist'
                    is_expected.to contain_yumrepo('os_updates').with_baseurl(
                      "https://simp.test/os/updates/\n    https://example.org/os/updates/\n    https://192.0.2.5/os/updates/"
                    )
                  end
                end
              end
            end

            context 'and `os_gpg_url` is set' do
              context 'to a valid string' do
                let(:params) { base_params.merge(os_gpg_url: 'https://YUM_SERVER/os/RPM-GPG-KEY-os') }

                it { is_expected.to compile.with_all_deps }
                it 'contains Yumrepo[os_updates]' do
                  case netlist[:desc]
                  when 'an empty netlist'
                    is_expected.to contain_yumrepo('os_updates').with_gpgkey('')
                  when 'a single-element netlist'
                    is_expected.to contain_yumrepo('os_updates').with_gpgkey('https://simp.test/os/RPM-GPG-KEY-os')
                  when 'a multi-element netlist'
                    is_expected.to contain_yumrepo('os_updates').with_gpgkey(
                      "https://simp.test/os/RPM-GPG-KEY-os\n       https://example.org/os/RPM-GPG-KEY-os\n       https://192.0.2.5/os/RPM-GPG-KEY-os"
                    )
                  end
                end
              end
            end

            context 'and `simp_update_url` is set' do
              context 'to a valid string' do
                let(:params) { base_params.merge(simp_update_url: 'https://YUM_SERVER/simp/updates/') }

                it { is_expected.to compile.with_all_deps }
                it 'contains Yumrepo[simp]' do
                  case netlist[:desc]
                  when 'an empty netlist'
                    is_expected.to contain_yumrepo('simp').with_baseurl('')
                  when 'a single-element netlist'
                    is_expected.to contain_yumrepo('simp').with_baseurl('https://simp.test/simp/updates/')
                  when 'a multi-element netlist'
                    is_expected.to contain_yumrepo('simp').with_baseurl(
                      "https://simp.test/simp/updates/\n    https://example.org/simp/updates/\n    https://192.0.2.5/simp/updates/"
                    )
                  end
                end
              end
            end

            context 'and `simp_gpg_url` is set' do
              context 'to a valid string' do
                let(:params) { base_params.merge(simp_gpg_url: 'https://YUM_SERVER/simp/RPM-GPG-KEY-simp') }

                it { is_expected.to compile.with_all_deps }
                it 'contains Yumrepo[simp]' do
                  case netlist[:desc]
                  when 'an empty netlist'
                    is_expected.to contain_yumrepo('simp').with_gpgkey('')
                  when 'a single-element netlist'
                    is_expected.to contain_yumrepo('simp').with_gpgkey('https://simp.test/simp/RPM-GPG-KEY-simp')
                  when 'a multi-element netlist'
                    is_expected.to contain_yumrepo('simp').with_gpgkey(
                      "https://simp.test/simp/RPM-GPG-KEY-simp\n       https://example.org/simp/RPM-GPG-KEY-simp\n       https://192.0.2.5/simp/RPM-GPG-KEY-simp"
                    )
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
