require 'spec_helper_acceptance'

test_name 'simp::server::rsync_shares class'

describe 'simp::server::rsync_shares class' do
  let(:manifest) do
    <<-EOS
      include 'simp::server::rsync_shares'
    EOS
  end

  hosts.each do |host|
    context 'default parameters, no rsync data' do
      let(:hieradata) do
        YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
          {
            'simp_options::stunnel' => true,
          },
        )
      end

      it 'sets simp_options via hiera' do
        set_hieradata_on(host, hieradata)
      end

      it 'applies with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end

    context 'default parameters, populated rsync' do
      it 'has rsync data' do
        scp_to(host, File.join(fixtures_path, 'acceptance', 'rsync_shares', 'simp'), '/var')
      end

      it 'applies with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end
  end
end
