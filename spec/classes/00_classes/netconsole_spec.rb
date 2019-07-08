require 'spec_helper'

describe 'simp::netconsole' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts[:networking] = {
          interfaces: {
            eth0: {
              ip: '192.168.2.56'
            }
          }
        }
        os_facts
      end
      let(:params) {{
        ensure:    'present',
        target_ip: '10.0.4.84'
      }}

      context 'with only required parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/etc/sysconfig/netconsole') \
          .with_content(/SYSLOGADDR=10.0.4.84/) }
        it { is_expected.to create_service('netconsole').with(
          ensure: 'running',
          enable: true
        ) }
      end

      context 'with everything set' do
        let(:params) { super().merge(
          target_macaddr: '00:11:22:33:44:55',
          source_device:  'enp3s0',
          source_port:    514,
          target_port:    514,
        ) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_service('netconsole').with(
          ensure: 'running',
          enable: true
        ) }
        [
          /SYSLOGADDR=10.0.4.84\s/,
          /LOCALPORT=514\s/,
          /DEV=enp3s0\s/,
          /SYSLOGPORT=514\s/,
          /SYSLOGMACADDR=00:11:22:33:44:55\s/
        ].each do |pattern|
          it { is_expected.to create_file('/etc/sysconfig/netconsole').with_content(pattern) }
        end
      end
      context 'disable' do
        let(:params) {{
          ensure: 'absent'
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/etc/sysconfig/netconsole') \
          .with_ensure('absent') }
        it { is_expected.to create_service('netconsole').with(
          ensure: 'stopped',
          enable: false
        ) }
      end

    end
  end
end
