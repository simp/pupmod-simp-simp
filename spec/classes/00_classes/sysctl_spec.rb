require 'spec_helper'

describe 'simp::sysctl' do
  def sysctls
    catalogue.resources.select { |r| r.type == 'Sysctl' }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
        else
          # 11.0.0 safe default: a bare include manages nothing
          context 'with default parameters' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::sysctl') }
            it { expect(sysctls).to be_empty }
            it { is_expected.not_to create_file('/var/core') }
            it { is_expected.not_to create_pam__limits__rule('prevent_core') }
            it { is_expected.not_to contain_class('pam') }
          end

          # Noop-safety: nothing at compile time depends on post-install facts
          context 'with default parameters and no simplib_sysctl fact' do
            let(:facts) { os_facts.reject { |fact, _value| fact.to_sym == :simplib_sysctl } }

            it { is_expected.to compile.with_all_deps }
            it { expect(sysctls).to be_empty }
          end

          context 'with one key set' do
            let(:params) { { net__ipv4__tcp_syncookies: 1 } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_sysctl('net.ipv4.tcp_syncookies').with(value: 1, silent: false).without_ensure }
            it { expect(sysctls.map(&:title)).to eq(['net.ipv4.tcp_syncookies']) }
          end

          context "with a key set to 'absent'" do
            let(:params) { { kernel__sysrq: 'absent' } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_sysctl('kernel.sysrq').with_ensure('absent').without_value }
          end

          context 'with a multi-value key set' do
            let(:params) { { net__ipv4__tcp_rmem: [4096, 98_304, 16_777_216] } }

            it { is_expected.to create_sysctl('net.ipv4.tcp_rmem').with_value('4096 98304 16777216') }
          end

          context "with a multi-value key set to 'absent'" do
            let(:params) { { net__ipv4__tcp_wmem: 'absent' } }

            it { is_expected.to create_sysctl('net.ipv4.tcp_wmem').with_ensure('absent') }
          end

          context 'with net__netfilter__nf_conntrack_max set' do
            let(:params) { { net__netfilter__nf_conntrack_max: 655_360 } }

            # This key may not exist until additional packages are present
            it { is_expected.to create_sysctl('net.netfilter.nf_conntrack_max').with(value: 655_360, silent: true) }
          end

          context 'with kernel__yama__ptrace_scope set' do
            let(:params) { { kernel__yama__ptrace_scope: 1 } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_sysctl('kernel.yama.ptrace_scope').with(value: 1) }
          end

          context 'with kernel__exec_shield set' do
            let(:params) { { kernel__exec_shield: 1 } }

            # Deprecated and has no effect
            it { is_expected.to compile.with_all_deps }
            it { expect(sysctls).to be_empty }
          end

          context 'with ipv6 enabled' do
            let(:params) do
              {
                ipv6: true,
                net__ipv6__conf__all__accept_redirects: 0,
              }
            end

            # silent => false so that live (running kernel) drift is still
            # enforced; see the note in manifests/sysctl.pp
            it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(value: 0, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_redirects').with(value: 0, silent: false) }
            it { is_expected.not_to create_sysctl('net.ipv6.conf.all.accept_source_route') }
          end

          context 'with ipv6 disabled' do
            let(:params) { { ipv6: false } }

            it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(value: 1, silent: false) }
            it { expect(sysctls.map(&:title)).to eq(['net.ipv6.conf.all.disable_ipv6']) }
          end

          context "with ipv6 set to 'absent'" do
            let(:params) { { ipv6: 'absent' } }

            it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with_ensure('absent').without_value }
          end

          # The IPv6 settings used to be gated on this fact, so a missing (or
          # stale) fact dropped them from the catalog entirely. os_facts is
          # symbol-keyed today, but normalize with to_sym so this keeps working
          # if that ever changes -- a key type mismatch here fails open and
          # leaves the fact in place, silently making the test a no-op.
          context 'with ipv6 disabled and no simplib_sysctl fact' do
            let(:params) do
              {
                ipv6: false,
                net__ipv6__conf__all__accept_source_route: 0,
              }
            end
            let(:facts) { os_facts.reject { |fact, _value| fact.to_sym == :simplib_sysctl } }

            it { is_expected.to compile.with_all_deps }

            # silent => true only here, because a missing fact means the keys
            # may not exist and the provider would otherwise fail on them
            it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(value: 1, silent: true) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_source_route').with(value: 0, silent: true) }
          end

          context 'kernel__core_pattern with absolute path' do
            let(:params) { { kernel__core_pattern: '/foo/bar/baz' } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_sysctl('kernel.core_pattern').with_value('/foo/bar/baz') }
          end

          context 'kernel__core_pattern with non-aboslute path' do
            let(:params) { { kernel__core_pattern: 'foo' } }

            it { is_expected.to compile.with_all_deps }
          end

          context 'kernel__core_pattern with pipe and absolute path' do
            let(:params) { { kernel__core_pattern: '| /bin/foo' } }

            it { is_expected.to compile.with_all_deps }
          end

          context 'kernel__core_pattern with pipe and non-absolute path' do
            let(:params) { { kernel__core_pattern: '| bin/foo' } }

            it {
              expect {
                is_expected.to compile.with_all_deps
              }.to raise_error(%r{Piped commands for kernel.core_pattern must have an absolute path})
            }
          end

          context 'kernel__core_pattern with over 128 characters' do
            let(:params) { { kernel__core_pattern: ('a' * 129) } }

            it {
              expect {
                is_expected.to compile.with_all_deps
              }.to raise_error(%r{must be less than 129 characters})
            }
          end

          context "kernel__core_pattern set to 'absent'" do
            let(:params) { { kernel__core_pattern: 'absent' } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_sysctl('kernel.core_pattern').with_ensure('absent') }
          end

          # Puppet's String comparison ignores case; only an exact 'absent'
          # removes the key
          context "kernel__core_pattern set to 'Absent'" do
            let(:params) { { kernel__core_pattern: 'Absent' } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_sysctl('kernel.core_pattern').with_value('Absent').without_ensure }
          end

          context 'with core_dumps => true' do
            let(:params) { { core_dumps: true } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_file('/var/core').with(ensure: 'directory', mode: '0640', before: []) }
            it { expect(sysctls).to be_empty }
          end

          context 'with core_dumps => true and the core keys set' do
            let(:params) do
              {
                core_dumps: true,
                kernel__core_pattern: '/var/core/%e.core',
                kernel__core_uses_pid: 1,
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_file('/var/core').that_comes_before('Sysctl[kernel.core_pattern]') }
            it { is_expected.to create_file('/var/core').that_comes_before('Sysctl[kernel.core_uses_pid]') }
          end

          context 'with pam => true and core_dumps => false' do
            let(:params) do
              {
                pam: true,
                core_dumps: false,
              }
            end

            it { is_expected.to create_pam__limits__rule('prevent_core') }
          end

          context 'with pam => true and core_dumps unset' do
            let(:params) { { pam: true } }

            it { is_expected.not_to create_pam__limits__rule('prevent_core') }
            it { is_expected.not_to contain_class('pam') }
          end

          context 'with pam => false and core_dumps => false' do
            let(:params) { { core_dumps: false } }

            it { is_expected.not_to create_pam__limits__rule('prevent_core') }
          end

          # Deprecated, but still honored
          context 'with unmanaged_sysctls listing set keys' do
            let(:params) do
              {
                net__core__somaxconn: 2048,
                net__core__rmem_max: 16_777_216,
                net__netfilter__nf_conntrack_max: 655_360,
                ipv6: false,
                unmanaged_sysctls: [
                  'net.core.somaxconn',
                  'net.netfilter.nf_conntrack_max',
                  'net.ipv6.conf.all.disable_ipv6',
                ],
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { expect(sysctls.map(&:title)).to eq(['net.core.rmem_max']) }
          end

          context 'with core_dumps => true and kernel.core_pattern in unmanaged_sysctls' do
            let(:params) do
              {
                core_dumps: true,
                kernel__core_pattern: '/var/core/%e.core',
                kernel__core_uses_pid: 1,
                unmanaged_sysctls: ['kernel.core_pattern'],
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.not_to create_sysctl('kernel.core_pattern') }
            it { is_expected.to create_file('/var/core').that_comes_before('Sysctl[kernel.core_uses_pid]') }
          end
        end
      end
    end
  end
end
