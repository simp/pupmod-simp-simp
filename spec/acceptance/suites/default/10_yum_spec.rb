require 'spec_helper_acceptance'

parallel = { run_in_parallel: ['yes', 'true', 'on'].include?(ENV['BEAKER_SIMP_parallel']) }

test_name 'simp yum configuration'

describe 'simp yum configuration' do
  let(:manifest) do
    <<-EOS
      include 'simp::server::yum'
      include 'simp::yum::repo::local_simp'
      include 'simp::yum::repo::local_os_updates'

      Class['simp::server::yum'] -> Class['simp::yum::repo::local_simp']
      Class['simp::server::yum'] -> Class['simp::yum::repo::local_os_updates']
    EOS
  end

  context 'with reliable test host' do
    let(:hieradata) do
      YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
        'simp::yum::repo::simp::servers'             => nil,
        'simp::yum::repo::local_os_updates::servers' => ['%{facts.networking.hostname}'],
        'simp::yum::repo::local_simp::servers'       => ['%{facts.networking.hostname}'],
      )
    end

    it 'works with no errors' do
      block_on(hosts, parallel) do |host|
        retry_on(host, 'yum install -y createrepo',
          max_retries: 3,
          retry_interval: 10)

        # Mock out the actual YUM repos
        os_data = fact_on(host, 'os')

        os_name = os_data['name']
        os_majrel = os_data['release']['major']
        repos = [
          "/var/www/yum/SIMP/#{os_name}/#{os_majrel}/x86_64",
          "/var/www/yum/#{os_name}/#{os_majrel}/x84_64/Updates",
        ]

        repos.each do |repo|
          on(host, "mkdir -p #{repo}")
          on(host, "cd #{repo}; createrepo -p .")
        end

        # Fix the SELinux contexts and permissions
        on(host, 'chmod -R go+rX /var/www')

        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)

        # This isn't something that we would expect Puppet to do based on how
        # we're creating the test repos
        on(host, 'chcon -R --reference=/var/www /var/www/yum')

        on(host, 'yum clean all')
        on(host, 'yum --disablerepo="*" --enablerepo="simp" list available > /dev/null')
      end
    end
  end
  context 'reset the yum repo back to normal' do
    it 'sets up hiera' do
      block_on(hosts, parallel) do |host|
        yum_updates_url = host.host_hash['yum_repos']['updates']['baseurl']

        hieradata = YAML.load_file(File.expand_path('files/default_hiera.yaml', __dir__)).merge(
          'simp::yum::repo::local_simp::enable_repo'   => false,
          'simp::yum::repo::local_simp::servers'       => [],
          'simp::yum::repo::local_os_updates::servers' => [yum_updates_url],
        )

        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end
    end
  end
end
