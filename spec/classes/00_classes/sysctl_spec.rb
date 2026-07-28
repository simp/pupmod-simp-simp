require 'spec_helper'

describe 'simp::sysctl' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
        else
          context 'with default parameters' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::sysctl') }
            it { is_expected.not_to create_file('/var/core').that_comes_before('Sysctl[kernel.core_pattern]') }
            it { is_expected.not_to create_file('/var/core').that_comes_before('Sysctl[kernel.core_uses_pid]') }
            # silent => false so that live (running kernel) drift is still
            # enforced; see the note in manifests/sysctl.pp
            it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(value: 1, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_source_route').with(value: 0, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.default.accept_source_route').with(value: 0, silent: false) }
            it { is_expected.to create_sysctl('fs.inotify.max_user_watches').with(value: 102_400) }
            it { is_expected.not_to create_sysctl('kernel.yama.ptrace_scope') }
          end

          context 'with kernel__yama__ptrace_scope set' do
            let(:params) { { kernel__yama__ptrace_scope: 1 } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_sysctl('kernel.yama.ptrace_scope').with(value: 1) }
          end

          context 'with ipv6 enabled' do
            let(:params) { { ipv6: true } }
            let(:facts) do
              os_facts.merge(ipv6_enabled: true)
            end

            it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(value: 0, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_redirects').with(value: 0, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_source_route').with(value: 0, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.default.accept_source_route').with(value: 0, silent: false) }
          end

          context 'with ipv6 disabled' do
            let(:params) do
              {
                ipv6: false,
                net__ipv6__conf__all__accept_redirects: 1,
                net__ipv6__conf__all__accept_source_route: 1,
                net__ipv6__conf__default__accept_source_route: 1,
              }
            end

            it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(value: 1, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_redirects').with(value: 1, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_source_route').with(value: 1, silent: false) }
            it { is_expected.to create_sysctl('net.ipv6.conf.default.accept_source_route').with(value: 1, silent: false) }
          end

          # The IPv6 settings used to be gated on this fact, so a missing (or
          # stale) fact dropped them from the catalog entirely. os_facts is
          # symbol-keyed today, but normalize with to_sym so this keeps working
          # if that ever changes -- a key type mismatch here fails open and
          # leaves the fact in place, silently making the test a no-op.
          context 'with ipv6 disabled and no simplib_sysctl fact' do
            let(:params) { { ipv6: false } }
            let(:facts) { os_facts.reject { |fact, _value| fact.to_sym == :simplib_sysctl } }

            it { is_expected.to compile.with_all_deps }

            # silent => true only here, because a missing fact means the keys
            # may not exist and the provider would otherwise fail on them
            it { is_expected.to create_sysctl('net.ipv6.conf.all.disable_ipv6').with(value: 1, silent: true) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_redirects').with(value: 0, silent: true) }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_source_route').with(value: 0, silent: true) }
            it { is_expected.to create_sysctl('net.ipv6.conf.default.accept_source_route').with(value: 0, silent: true) }
          end

          context 'with ipv6 disabled and the ipv6 keys in unmanaged_sysctls' do
            let(:params) do
              {
                ipv6: false,
                unmanaged_sysctls: ['net.ipv6.conf.all.disable_ipv6'],
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.not_to create_sysctl('net.ipv6.conf.all.disable_ipv6') }
            it { is_expected.to create_sysctl('net.ipv6.conf.all.accept_redirects') }
          end

          context 'kernel__core_pattern with absolute path' do
            let(:params) do
              {
                kernel__core_pattern: '/foo/bar/baz',
              }
            end

            it { is_expected.to compile.with_all_deps }
          end

          context 'kernel__core_pattern with non-aboslute path' do
            let(:params) do
              {
                kernel__core_pattern: 'foo',
              }
            end

            it { is_expected.to compile.with_all_deps }
          end

          context 'kernel__core_pattern with pipe and absolute path' do
            let(:params) do
              {
                kernel__core_pattern: '| /bin/foo',
              }
            end

            it { is_expected.to compile.with_all_deps }
          end

          context 'kernel__core_pattern with pipe and non-absolute path' do
            let(:params) do
              {
                kernel__core_pattern: '| bin/foo',
              }
            end

            it {
              expect {
                is_expected.to compile.with_all_deps
              }.to raise_error(%r{Piped commands for kernel.core_pattern must have an absolute path})
            }
          end

          context 'kernel__core_pattern with over 128 characters' do
            let(:params) do
              {
                kernel__core_pattern: ('a' * 129),
              }
            end

            it {
              expect {
                is_expected.to compile.with_all_deps
              }.to raise_error(%r{must be less than 129 characters})
            }
          end

          context 'with core_dumps => true' do
            let(:params) { { core_dumps: true } }

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

          context 'with unmanaged_sysctls listing specific keys' do
            let(:params) do
              {
                unmanaged_sysctls: [
                  'net.core.somaxconn',
                  'fs.inotify.max_user_watches',
                  'kernel.randomize_va_space',
                  'net.netfilter.nf_conntrack_max',
                ],
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.not_to create_sysctl('net.core.somaxconn') }
            it { is_expected.not_to create_sysctl('fs.inotify.max_user_watches') }
            it { is_expected.not_to create_sysctl('kernel.randomize_va_space') }
            it { is_expected.not_to create_sysctl('net.netfilter.nf_conntrack_max') }
            # untouched neighbors are still managed
            it { is_expected.to create_sysctl('net.core.rmem_max').with(value: 16_777_216) }
            it { is_expected.to create_sysctl('kernel.dmesg_restrict').with(value: 1) }
          end

          context 'with core_dumps => true and kernel.core_pattern in unmanaged_sysctls' do
            let(:params) do
              {
                core_dumps: true,
                unmanaged_sysctls: ['kernel.core_pattern'],
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_file('/var/core') }
            it { is_expected.not_to create_sysctl('kernel.core_pattern') }
            it { is_expected.to create_file('/var/core').that_comes_before('Sysctl[kernel.core_uses_pid]') }
          end
        end
      end
    end
  end
end
