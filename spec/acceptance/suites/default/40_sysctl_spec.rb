require 'spec_helper_acceptance'

test_name 'simp::sysctl class'

describe 'simp::sysctl class' do
  let(:manifest) do
    <<-EOS
      include 'simp::sysctl'
    EOS
  end

  let(:default_hieradata) do
    YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__))
  end

  # Runs the block with the Compliance Engine Hiera backend added to the
  # environment's hiera.yaml, then puts the original back. The Compliance
  # Engine layer goes last, so it has the lowest priority, as it does at a
  # real site.
  def with_compliance_engine(host)
    original = get_hiera_config_on(host)
    config = YAML.safe_load(original)
    config['hierarchy'] << {
      'name'       => 'Compliance Engine',
      'lookup_key' => 'compliance_engine::enforcement',
    }
    set_hiera_config_on(host, config)

    yield
  ensure
    set_hiera_config_on(host, original) if original
  end

  def sysctl_conf_line(host, key)
    on(host, "grep -E '^\\s*#{Regexp.escape(key)}\\s*=' /etc/sysctl.conf", acceptable_exit_codes: [0, 1]).stdout.strip
  end

  def live_value(host, key)
    on(host, "sysctl -n #{key}").stdout.strip
  end

  hosts.each do |host|
    # 11.0.0 safe default: a bare include manages nothing
    context 'default parameters (bare include)' do
      it 'resets hieradata' do
        set_hieradata_on(host, default_hieradata)
      end

      it 'applies with no errors and no changes' do
        on(host, 'cp -p /etc/sysctl.conf /root/sysctl.conf.before')
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'does not modify /etc/sysctl.conf' do
        on(host, 'cmp /etc/sysctl.conf /root/sysctl.conf.before')
      end
    end

    # The core principle: set, unset (stays), absent (removed)
    context 'one key, enforced alone' do
      let(:key) { 'kernel.panic' }

      context 'when set' do
        it 'sets hieradata' do
          set_hieradata_on(host, default_hieradata.merge('simp::sysctl::kernel__panic' => 7))
        end

        it 'applies with no errors' do
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        it 'is idempotent' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'is persisted and live' do
          expect(sysctl_conf_line(host, key)).to match(%r{=\s*7\z})
          expect(live_value(host, key)).to eq('7')
        end
      end

      context 'when unset again' do
        it 'resets hieradata' do
          set_hieradata_on(host, default_hieradata)
        end

        it 'applies with no changes' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'leaves the value in place' do
          expect(sysctl_conf_line(host, key)).to match(%r{=\s*7\z})
          expect(live_value(host, key)).to eq('7')
        end
      end

      context "when set to 'absent'" do
        it 'sets hieradata' do
          set_hieradata_on(host, default_hieradata.merge('simp::sysctl::kernel__panic' => 'absent'))
        end

        it 'applies with no errors' do
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        it 'is idempotent' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'removes the key from /etc/sysctl.conf' do
          expect(sysctl_conf_line(host, key)).to be_empty
        end

        it 'does not reset the running kernel value' do
          expect(live_value(host, key)).to eq('7')
        end
      end
    end

    context 'with simp:defaults enforced' do
      let(:hieradata) do
        default_hieradata.merge('compliance_engine::enforcement' => ['simp:defaults'])
      end

      it 'previews under noop with no errors' do
        with_compliance_engine(host) do
          set_hieradata_on(host, hieradata)
          result = apply_manifest_on(host, manifest, noop: true, catch_failures: true)

          expect(result.output).to match(%r{Sysctl\[kernel\.panic\].*\(noop\)})
          expect(result.output).to match(%r{Sysctl\[net\.core\.somaxconn\].*\(noop\)})
        end
      end

      it 'applies with no errors and is idempotent' do
        with_compliance_engine(host) do
          set_hieradata_on(host, hieradata)
          apply_manifest_on(host, manifest, catch_failures: true)
          apply_manifest_on(host, manifest, catch_changes: true)
        end
      end

      it 'restores the pre-11.0.0 values' do
        expect(live_value(host, 'kernel.panic')).to eq('10')
        expect(live_value(host, 'net.core.somaxconn')).to eq('2048')
        expect(live_value(host, 'net.ipv4.tcp_rmem')).to match(%r{\A4096\s+98304\s+16777216\z})
        expect(sysctl_conf_line(host, 'kernel.dmesg_restrict')).to match(%r{=\s*1\z})
      end

      it 'disables IPv6' do
        expect(live_value(host, 'net.ipv6.conf.all.disable_ipv6')).to eq('1')
      end

      context 'with ipv6 overridden in site Hiera' do
        it 'enables IPv6' do
          with_compliance_engine(host) do
            set_hieradata_on(host, hieradata.merge('simp::sysctl::ipv6' => true))
            apply_manifest_on(host, manifest, catch_failures: true)
            apply_manifest_on(host, manifest, catch_changes: true)
          end

          expect(live_value(host, 'net.ipv6.conf.all.disable_ipv6')).to eq('0')
        end
      end
    end
  end
end
