require 'spec_helper_acceptance'

test_name 'simp::server::rsync_shares class'

describe 'simp::server::rsync_shares class' do
  let(:manifest) {
    <<-EOS
      include 'simp::server::rsync_shares'
    EOS
  }

  hosts.each do |host|
    context 'default parameters, no rsync data' do
      it 'should set simp_options via hiera' do
        yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/environments/production/hieradata/common.yaml').stdout)
        default_yaml = yaml.merge(
          'simp_options::stunnel' => true
        ).to_yaml
        create_remote_file(host, '/etc/puppetlabs/code/environments/production/hieradata/common.yaml', default_yaml)
      end

      it 'should apply with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end

    context 'default parameters, populated rsync' do
      it 'should have rsync data' do
        scp_to(host, File.join(fixtures_path, 'acceptance', 'rsync_shares', 'simp'), '/var')
      end

      it 'should apply with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end
  end
end
