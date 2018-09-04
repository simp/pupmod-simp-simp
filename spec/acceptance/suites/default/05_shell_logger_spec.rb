require 'spec_helper_acceptance'

test_name 'simp_admin'

describe 'simp_admin' do
  let(:manifest) {
    <<-EOS
      include 'simp::admin'
    EOS
  }

  hosts.each do |host|
    context "on #{host}" do

      context 'logging shell' do
        context 'using tlog (default)' do
          it 'should run puppet' do
            apply_manifest_on(host, manifest, :catch_changes => false)
          end

          it 'should be idempotent' do
            apply_manifest_on(host, manifest, :catch_changes => true)
          end

          it 'should have tlog installed' do
            expect(host.check_for_package('tlog')).to be true
          end
        end

        context 'switching to sudosh' do
          it 'should switch to sudosh via hiera' do
            yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
            default_yaml = yaml.merge(
              'simp::admin::logged_shell' => 'sudosh'
            ).to_yaml
            create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
          end

          it 'should run puppet' do
            apply_manifest_on(host, manifest, :catch_changes => false)
          end

          it 'should be idempotent' do
            apply_manifest_on(host, manifest, :catch_changes => true)
          end

          it 'should have sudosh2 installed' do
            expect(host.check_for_package('sudosh2')).to be true
          end

          it 'should not have any tlog profile scripts installed' do
            expect(on(host, 'ls /etc/profile.d/00-simp-tlog.*', :accept_all_exit_codes => true).stdout.strip).to be_empty
          end
        end

        context 'switching back to tlog' do
          it 'should switch back to tlog via hiera' do
            yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
            default_yaml = yaml.merge(
              'simp::admin::logged_shell' => 'tlog'
            ).to_yaml
            create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
          end

          it 'should run puppet' do
            apply_manifest_on(host, manifest, :catch_changes => false)
          end

          it 'should be idempotent' do
            apply_manifest_on(host, manifest, :catch_changes => true)
          end

          it 'should have tlog installed' do
            expect(host.check_for_package('sudosh2')).to be true
          end

          it 'should not have any sudosh profile scripts installed' do
            expect(on(host, 'ls /etc/profile.d/sudosh*', :accept_all_exit_codes => true).stdout.strip).to be_empty
          end
        end
      end
    end
  end
end
