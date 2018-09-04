require 'spec_helper_acceptance'
require 'json'

test_name 'simp::prelink'

describe 'simp::prelink class' do
  let(:manifest) {
    <<-EOS
      include 'simp::prelink'
    EOS
  }

  hosts.each do |host|
    context "on #{host}" do
      context 'with default parameters' do
        it 'should apply manifest' do
          apply_manifest_on(host, manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(host, manifest, :catch_changes => true)
        end

        it 'should ensure prelink package is absent' do
          expect( check_for_package(host, 'prelink') ).to be false
        end
      end

      context 'with prelink enabled' do
        it 'should enable prelink via hiera' do
          yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
          default_yaml = yaml.merge(
            'simp::prelink::enable' => true
          ).to_yaml
          create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
        end

        it 'should apply manifest' do
          apply_manifest_on(host, manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(host, manifest, :catch_changes => true)
        end

        it 'should install prelink package only if not in FIPS mode' do
          facts = JSON.load(on(host, 'puppet facts').stdout)
          if facts['values']['fips_enabled']
            expect( check_for_package(host, 'prelink') ).to be false
          else
            expect( check_for_package(host, 'prelink') ).to be true
          end
        end

        it 'should enable prelink only if not in FIPS mode' do
          facts = JSON.load(on(host, 'puppet facts').stdout)
          if facts['values']['fips_enabled']
            expect( facts['values']['prelink'] ).to be nil
          else
            expect( facts['values']['prelink'] ).to_not be nil
            expect( facts['values']['prelink']['enabled'] ).to be true
          end
        end

        it 'should run prelink only if not in FIPS mode' do
          facts = JSON.load(on(host, 'puppet facts').stdout)
          if facts['values']['fips_enabled']
            result = on(host, 'ls /etc/prelink.cache', :acceptable_exit_codes => [2])
          else
            # first see if prelink cron job has already run
            result = on(host, 'ls /etc/prelink.cache', :acceptable_exit_codes => [0,2])

            if result.exit_code == 2
              # prelink cron job has not yet been run, so try to run it
              on(host, '/etc/cron.daily/prelink')
              on(host, 'ls /etc/prelink.cache')
            end
          end
        end
      end

      context 'with prelink disabled after being enabled' do
        it 'should disable prelink via hiera' do
          yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
          default_yaml = yaml.merge(
            'simp::prelink::enable' => false
          ).to_yaml
          create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
        end

        it 'should apply manifest' do
          apply_manifest_on(host, manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(host, manifest, :catch_changes => true)
        end

        it 'should remove prelink cache when prelink is disabled' do
          on(host, 'ls /etc/prelink.cache', :acceptable_exit_codes => [2])
        end

        it 'should uninstall prelink package' do
          expect( check_for_package(host, 'prelink') ).to be false
        end
      end
    end
  end
end
