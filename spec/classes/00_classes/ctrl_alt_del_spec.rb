require 'spec_helper'

describe 'simp::ctrl_alt_del' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows .+' is not supported/) }
        else
          shared_examples_for "a systemd system" do
            it { is_expected.to compile.with_all_deps }

            it { is_expected.to create_class('simp::ctrl_alt_del') }

            it { is_expected.to create_file('/etc/systemd/system/ctrl-alt-del.target') }
            it {
              is_expected.to create_file('/etc/systemd/system/ctrl-alt-del-capture.service')
                .with_content(/SyslogFacility=local6/)
            }
            it {
              is_expected.to create_file('/etc/systemd/system/ctrl-alt-del-capture.service')
                .with_content(/SyslogLevel=warning/)
            }
          end

          if os_facts.fetch(:init_systems, []).include?('systemd')
            it_behaves_like 'a systemd system'

            it {
              is_expected.to create_file('/etc/systemd/system/ctrl-alt-del-capture.service')
                .with_content(
                  %r{ExecStart=/bin/sh -c "/bin/echo -n 'Ctrl-Alt-Del detected - Logged in users:' `/usr/bin/who | /bin/cut -f1 -d' ' | /bin/sort -u | /usr/bin/tr '\\n' ' '`"\n}
                )
            }

            context 'when not logging users' do
              let(:params){{
                :log_users => false
              }}

              it_behaves_like 'a systemd system'

              it {
                is_expected.to create_file('/etc/systemd/system/ctrl-alt-del-capture.service')
                  .with_content(
                    %r{ExecStart=/bin/sh -c "/bin/echo -n 'Ctrl-Alt-Del detected'"\n}
                  )
              }
            end

            context 'when not logging' do
              let(:params){{
                :log => false
              }}

              it { is_expected.to compile.with_all_deps }

              it { is_expected.to create_file('/etc/systemd/system/ctrl-alt-del.target').with_target('/dev/null') }
              it { is_expected.to create_file('/etc/systemd/system/ctrl-alt-del-capture.service').with_ensure('absent') }
            end

            context 'when allowing ctrl-alt-del' do
              let(:params){{
                :enable => true
              }}

              it { is_expected.to compile.with_all_deps }

              it { is_expected.to create_file('/etc/systemd/system/ctrl-alt-del.target').with_ensure('absent') }
              it { is_expected.to create_file('/etc/systemd/system/ctrl-alt-del-capture.service').with_ensure('absent') }
            end
          else
            it {
              expect {
                is_expected.to compile.with_all_deps
              }.to raise_error(/not find supported init/)
            }
          end
        end
      end
    end
  end
end
