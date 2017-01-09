require 'spec_helper'

describe 'simp::ctrl_alt_del' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) { facts }

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

        shared_examples_for "an upstart system" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to create_class('simp::ctrl_alt_del') }
          it { is_expected.to create_class('upstart') }

          it { is_expected.to create_upstart__job('control-alt-delete').with_start_on('control-alt-delete') }
        end

        if facts[:init_systems].include?('systemd')
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
        elsif facts[:init_systems].include?('upstart')
          it_behaves_like 'an upstart system'

          it { is_expected.to create_upstart__job('control-alt-delete').with_main_process(
            %{/bin/sh -c "/bin/logger -p local6.warning 'Ctrl-Alt-Del detected - Logged in users:' `/usr/bin/who | /bin/cut -f1 -d' ' | /bin/sort -u | /usr/bin/tr '\\n' ' '`"}
          )}

          context 'when not logging users' do
            let(:params){{
              :log_users => false
            }}

            it_behaves_like 'an upstart system'

            it { is_expected.to create_upstart__job('control-alt-delete').with_main_process(%{/bin/sh -c "/bin/logger -p local6.warning 'Ctrl-Alt-Del detected'"}) }
          end

          context 'when not logging' do
            let(:params){{
              :log => false
            }}

            it_behaves_like 'an upstart system'

            it { is_expected.to create_upstart__job('control-alt-delete').with_main_process('/bin/true') }
          end

          context 'when allowing ctrl-alt-del' do
            let(:params){{
              :enable => true
            }}

            it_behaves_like 'an upstart system'

            it { is_expected.to create_upstart__job('control-alt-delete').with_main_process('/sbin/shutdown -r now "Control-Alt-Delete pressed"') }
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
