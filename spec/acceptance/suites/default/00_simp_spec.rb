require 'spec_helper_acceptance'

test_name 'simp'

describe 'simp class' do
  let(:manifest) {
    <<-EOS
      # This would be in site.pp, or an ENC or classifier
      include 'simp_options'
      include 'simp'
      include 'simp::yum::repo::local_os_updates'
    EOS
  }

  context 'on each host' do
    hosts.each do |host|
      let(:host_fqdn) { fact_on(host, 'fqdn') }

      it 'should set up hiera' do
        yum_updates_url = host.host_hash['yum_repos']['updates']['baseurl']

        yaml = YAML.load(File.read('spec/acceptance/suites/default/files/default_hiera.yaml'))
        default_yaml = yaml.merge(
          # 'simp_options::log_servers'    => [host _fqdn],
          # 'simp::yum::servers'           => [host_fqdn],
          'simp_options::puppet::server'   => host_fqdn,
          'simp_options::puppet::ca'       => host_fqdn,
          'simp::yum::repo::simp::servers' => [host_fqdn],
          'simp::yum::repo::local_os_updates::servers' => [yum_updates_url],
        ).to_yaml

        on(host, 'mkdir -p /etc/puppetlabs/code/{,hiera}data/ /etc/puppetlabs/code/environments/production/{,hiera}data')
        create_remote_file(host, '/etc/puppetlabs/code/hieradata/common.yaml', default_yaml)
        on(host, 'ln -s /etc/puppetlabs/code/hieradata/common.yaml /etc/puppetlabs/code/data/common.yaml')
        on(host, 'ln -s /etc/puppetlabs/code/hieradata/common.yaml /etc/puppetlabs/code/environments/production/hieradata/common.yaml')
        on(host, 'ln -s /etc/puppetlabs/code/hieradata/common.yaml /etc/puppetlabs/code/environments/production/data/common.yaml')
      end

      # These boxes have no root password by default...
      it 'should set the root password' do
        on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
        on(host, 'echo "root:password" | chpasswd --crypt-method SHA256')
      end

      it 'should bootstrap in a few runs' do
        apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
        apply_manifest_on(host, manifest, :accept_all_exit_codes => true)
        host.reboot
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end
  end
end
