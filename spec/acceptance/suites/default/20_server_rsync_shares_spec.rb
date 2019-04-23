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
      let(:hieradata){
        YAML.load(File.read(File.expand_path('files/default_hiera.yaml', __dir__))).merge(
          {
            'simp_options::stunnel' => true
          }
        )
      }

      it 'should set simp_options via hiera' do
        set_hieradata_on(host, hieradata)
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
