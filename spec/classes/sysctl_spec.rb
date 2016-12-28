require 'spec_helper'

describe 'simp::sysctl' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      context "with default parameters" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::sysctl') }
        it { is_expected.to create_file('/var/core').that_comes_before('Sysctl[kernel.core_pattern]') }
        it { is_expected.to create_file('/var/core').that_comes_before('Sysctl[kernel.core_uses_pid]') }
      end

      context "with ipv6_enabled = true" do
        let(:facts) do
          facts[:ipv6_enabled] = true
          facts
        end

        it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(:value => 1 ) }
      end

      context "with ipv6 = false and ipv6_enabled = true" do
        new_facts = facts.dup
        new_facts[:ipv6_enabled] = true
        let(:facts) { new_facts }
        let(:params) {{ :ipv6 => false }}
        it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(:value => 1 ) }
      end

      context "kernel__core_pattern with absolute path" do
        let(:params) {{
          :kernel__core_pattern => '/foo/bar/baz'
        }}
        it { is_expected.to compile.with_all_deps }
      end

      context "kernel__core_pattern with non-aboslute path" do
        let(:params) {{
          :kernel__core_pattern => 'foo'
        }}
        it { is_expected.to compile.with_all_deps }
      end

      context "kernel__core_pattern with pipe and absolute path" do
        let(:params) {{
          :kernel__core_pattern => '| /bin/foo'
        }}
        it { is_expected.to compile.with_all_deps }
      end

      context "kernel__core_pattern with pipe and non-absolute path" do
        let(:params) {{
          :kernel__core_pattern => '| bin/foo'
        }}
        it {
          expect {
            is_expected.to compile.with_all_deps
          }.to raise_error(/Piped commands for kernel.core_pattern must have an absolute path/)
        }
      end

      context "kernel__core_pattern with over 128 characters" do
        let(:params) {{
          :kernel__core_pattern => ('a'*129)
        }}
        it {
          expect {
            is_expected.to compile.with_all_deps
          }.to raise_error(/must be less than 129 characters/)
        }
      end

      context 'with core_dumps => false' do
        it { is_expected.to create_pam__limits__add('prevent_core') }
      end

    end
  end
end
