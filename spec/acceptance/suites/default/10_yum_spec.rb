require 'spec_helper_acceptance'

test_name 'simp yum configuration'

describe 'simp yum configuration' do
  let(:manifest) {
    <<-EOS
      include 'simp::server::yum'
      include 'simp::yum::repo::local_simp'
      include 'simp::yum::repo::local_os_updates'

      Class['simp::server::yum'] -> Class['simp::yum::repo::local_simp']
      Class['simp::server::yum'] -> Class['simp::yum::repo::local_os_updates']
    EOS
  }

  context 'with reliable test host' do
    it 'should work with no errors' do
      block_on(hosts, :run_in_parallel => true) do |host|
        retry_on(host, 'yum install -y createrepo',
          :max_retries    => 3,
          :retry_interval => 10
        )

        # Mock out the actual YUM repos
        repos = [
          '/var/www/yum/SIMP/x86_64',
          '/var/www/yum/CentOS/7/x86_64/Updates',
          '/var/www/yum/CentOS/6/x86_64/Updates'
        ]

        repos.each do |repo|
          on(host, "mkdir -p #{repo}")
          on(host, "cd #{repo}; createrepo -p .")
        end

        # Fix the SELinux contexts and permissions
        on(host, 'chmod -R go+rX /var/www')

        yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/hieradata/default.yaml').stdout)
        default_yaml = yaml.merge(
          'simp::yum::repo::simp::servers'             => nil,
          'simp::yum::repo::local_os_updates::servers' => ["%{facts.hostname}"],
          'simp::yum::repo::local_simp::servers'       => ["%{facts.hostname}"],
        ).to_yaml
        set_hieradata_on(host, default_yaml)

        apply_manifest_on(host, manifest, :catch_failures => true)

        # This isn't something that we would expect Puppet to do based on how
        # we're creating the test repos
        on(host, 'chcon -R --reference=/var/www /var/www/yum')

        on(host, 'yum clean all')
        on(host, 'yum --disablerepo="*" --enablerepo="simp" list available > /dev/null')
      end
    end
  end
  context 'reset the yum repo back to normal' do
    it 'should set up hiera' do
      block_on(hosts, :run_in_parallel => true) do |host|
        os = JSON.load(on(host,'puppet facts').stdout)['values']['os']
        yum_updates_url = case "#{os['name']}-#{os['release']['full']}"
          when /OracleLinux-7/
            'http://public-yum.oracle.com/repo/OracleLinux/OL7/latest/$basearch/'
          when /OracleLinux-6/
            'http://public-yum.oracle.com/repo/OracleLinux/OL6/latest/$basearch/'
          else
            'http://mirror.centos.org/centos/$releasever/os/$basearch/'
          end

        yaml         = YAML.load(on(host,'cat /etc/puppetlabs/code/hieradata/default.yaml').stdout)
        default_yaml = yaml.merge(
          'simp::yum::repo::local_simp::enable_repo'   => false,
          'simp::yum::repo::local_simp::servers'       => [],
          'simp::yum::repo::local_os_updates::servers' => [yum_updates_url],
        ).to_yaml

        set_hieradata_on(host, default_yaml)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end
    end
  end
end
