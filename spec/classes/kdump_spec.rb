require 'spec_helper'

describe 'simp::kdump' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do

        shared_examples_for "a structured module" do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::kdump') }
          it { is_expected.to contain_reboot_notify('kdump_reboot')}
        end

        context 'with default params' do
          let(:facts) {
            os_facts.merge( :memorysize_mb => 2500 )
          }
          let(:params) {{ :package_ensure => 'installed' }}

          it_behaves_like "a structured module"
          it { is_expected.to create_kernel_parameter('crashkernel').with({
            'ensure' => 'absent',
            'notify' => 'Reboot_notify[kdump_reboot]'
          })}
          it { is_expected.to create_package('kexec-tools').with({:ensure => 'absent'}) }
        end

        context 'with enabled = true' do
          let(:facts) {
            os_facts.merge( :memorysize_mb => 2500 )
          }
          let(:params) {{
            :package_ensure => 'installed',
            :enabled        => true
          }}

          it_behaves_like "a structured module"
          it { is_expected.to create_package('kexec-tools').with_ensure('installed') }
          it { is_expected.to create_kernel_parameter('crashkernel').with({
            'ensure' => 'present',
            'notify' => 'Reboot_notify[kdump_reboot]',
            'value'  => 'auto'
          } )}
        end

        context 'with params set' do
          let(:facts) {
            os_facts.merge( :memorysize_mb => 2500 )
          }
          let(:params) {{
            :package_ensure => 'latest',
            :crashkernel    => '32M',
            :enabled        => true
          }}

          it_behaves_like "a structured module"
          it { is_expected.to create_package('kexec-tools').with_ensure('latest') }
          it { is_expected.to create_kernel_parameter('crashkernel').with({
            'ensure' => 'present',
            'notify' => 'Reboot_notify[kdump_reboot]',
            'value'  => '32M'
          } )}
        end

        context 'with enabled = true, crashkernel = auto and memory < 1G' do
          let(:params) {{
            :package_ensure => 'installed',
            :enabled        => true
          }}

          let(:facts) {
            os_facts.merge( :memorysize_mb => 500 )
          }

          it_behaves_like "a structured module"
          it { is_expected.to create_package('kexec-tools').with_ensure('installed') }
          it { is_expected.to  contain_notify('kdump_memory_warning') }
          it { is_expected.to create_kernel_parameter('crashkernel').with({
            'ensure' => 'present',
            'notify' => 'Reboot_notify[kdump_reboot]',
            'value'  => 'auto'
          } )}
        end

      end
    end
  end
end
