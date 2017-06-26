require 'spec_helper_acceptance'

test_name 'simp::server::rsync_shares class'

describe 'simp::server::rsync_shares class' do
  let(:hieradata) {{
    'simp_options::pki'          => true,
    'simp_options::pki::source'  => '/etc/pki/simp-testing/pki',
    'simp_options::stunnel'      => true,
    'simp_options::trusted_nets' => ['ALL'],
    # Settings to make beaker happy
    'ssh::server::conf::permitrootlogin'    => true,
    'ssh::server::conf::authorizedkeysfile' => '.ssh/authorized_keys',
    'useradd::securetty'                    => ['ANY_SHELL']
  }}

  let(:manifest) {
    <<-EOS
      include 'simp::server::rsync_shares'
    EOS
  }

  hosts.each do |host|
    context 'default parameters, no rsync data' do

      it 'should apply with no errors' do
        set_hieradata_on(host, hieradata)
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
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end
  end
end
