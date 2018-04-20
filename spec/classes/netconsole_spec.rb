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
        it { is_expected.to create_kernel_parameter('netconsole') \
          .with_value('6665@192.168.2.56/eth0,6666@10.0.4.84/') }
      end

      context 'with everything set' do
        let(:params) { super().merge(
          target_macaddr:   '00:11:22:33:44:55',
          source_device:    'enp3s0',
          source_ip:        '192.168.2.4',
          source_port:      514,
          target_port:      514,
          extended_console: true
        ) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_kernel_parameter('netconsole') \
          .with_value('+514@192.168.2.4/enp3s0,514@10.0.4.84/00:11:22:33:44:55') }
      end

      context 'with everything set to empty strings' do
        let(:params) { super().merge(
          target_macaddr:   '',
          source_device:    '',
          source_ip:        '',
          source_port:      '',
          target_port:      '',
          extended_console: false
        ) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_kernel_parameter('netconsole') \
          .with_value('@/,@10.0.4.84/') }
      end
    end
  end
end
