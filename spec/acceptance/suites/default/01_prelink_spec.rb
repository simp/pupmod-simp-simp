require 'spec_helper_acceptance'
require 'json'

test_name 'simp::prelink'

describe 'simp::prelink class' do
  let(:manifest) do
    <<-EOS
      include 'simp::prelink'
    EOS
  end

  hosts.each do |host|
    os_major = fact_on(host, 'os.release.major')

    if os_major == '7'
      context 'with default parameters' do
        it 'applies manifest' do
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        it 'is idempotent' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'ensures prelink package is absent' do
          expect(check_for_package(host, 'prelink')).to be false
        end
      end

      context 'with prelink enabled' do
        let(:hieradata) do
          YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
            {
              'simp::prelink::enable' => true
            },
          )
        end

        it 'enables prelink via hiera' do
          set_hieradata_on(host, hieradata)
        end

        it 'applies manifest' do
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        it 'is idempotent' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'installs prelink package only if not in FIPS mode' do
          if fact_on(host, 'fips_enabled')
            expect(check_for_package(host, 'prelink')).to be false
          else
            expect(check_for_package(host, 'prelink')).to be true
          end
        end

        it 'enables prelink only if not in FIPS mode' do
          if fact_on(host, 'fips_enabled')
            expect(pfact_on(host, 'prelink')).to eq ''
          else
            expect(pfact_on(host, 'prelink')).not_to eq ''
            expect(pfact_on(host, 'prelink.enabled')).to be true
          end
        end

        it 'runs prelink only if not in FIPS mode' do
          if fact_on(host, 'fips_enabled')
            on(host, 'ls /etc/prelink.cache', acceptable_exit_codes: [2])
          else
            # first see if prelink cron job has already run
            result = on(host, 'ls /etc/prelink.cache', acceptable_exit_codes: [0, 2])

            if result.exit_code == 2
              # prelink cron job has not yet been run, so try to run it
              on(host, '/etc/cron.daily/prelink')
              on(host, 'ls /etc/prelink.cache')
            end
          end
        end
      end

      context 'with prelink disabled after being enabled' do
        let(:hieradata) do
          YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
            {
              'simp::prelink::enable' => false
            },
          )
        end

        it 'disables prelink via hiera' do
          set_hieradata_on(host, hieradata)
        end

        it 'applies manifest' do
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        it 'is idempotent' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'removes prelink cache when prelink is disabled' do
          on(host, 'ls /etc/prelink.cache', acceptable_exit_codes: [2])
        end

        it 'uninstalls prelink package' do
          expect(check_for_package(host, 'prelink')).to be false
        end
      end
    else
      it 'does not have prelink capabilities'
    end
  end
end
