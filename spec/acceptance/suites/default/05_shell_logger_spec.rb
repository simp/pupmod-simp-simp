require 'spec_helper_acceptance'

test_name 'simp_admin'

describe 'simp_admin' do
  let(:manifest) do
    <<-EOS
      include 'simp::admin'
    EOS
  end

  hosts.each do |host|
    context "on #{host}" do
      context 'logging shell' do
        context 'using tlog (default)' do
          it 'runs puppet' do
            apply_manifest_on(host, manifest, catch_changes: false)
          end

          it 'is idempotent' do
            apply_manifest_on(host, manifest, catch_changes: true)
          end

          it 'has tlog installed' do
            expect(host.check_for_package('tlog')).to be true
          end
        end

        os_major = fact_on(host, 'os.release.major')

        if os_major == '7'
          context 'switching to sudosh' do
            let(:hieradata)  do
              YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
                'simp::admin::logged_shell' => 'sudosh',
              )
            end

            it 'switches to sudosh via hiera' do
              set_hieradata_on(host, hieradata)
            end

            it 'runs puppet' do
              apply_manifest_on(host, manifest, catch_changes: false)
            end

            it 'is idempotent' do
              apply_manifest_on(host, manifest, catch_changes: true)
            end

            it 'has sudosh2 installed' do
              expect(host.check_for_package('sudosh2')).to be true
            end

            it 'does not have any tlog profile scripts installed' do
              expect(on(host, 'ls /etc/profile.d/00-simp-tlog.*', accept_all_exit_codes: true).stdout.strip).to be_empty
            end
          end

          context 'switching back to tlog' do
            let(:hieradata)  do
              YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
                'simp::admin::logged_shell' => 'tlog',
              )
            end

            it 'switches back to tlog via hiera' do
              set_hieradata_on(host, hieradata)
            end

            it 'runs puppet' do
              apply_manifest_on(host, manifest, catch_changes: false)
            end

            it 'is idempotent' do
              apply_manifest_on(host, manifest, catch_changes: true)
            end

            it 'has tlog installed' do
              expect(host.check_for_package('sudosh2')).to be true
            end

            it 'does not have any sudosh profile scripts installed' do
              expect(on(host, 'ls /etc/profile.d/sudosh*', accept_all_exit_codes: true).stdout.strip).to be_empty
            end
          end
        end
      end
    end
  end
end
