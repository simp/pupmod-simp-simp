require 'spec_helper_acceptance'

test_name 'simp::yum class'

describe 'simp::yum class' do
  before(:context) do
    hosts.each do |host|
      interfaces = fact_on(host, 'interfaces').strip.split(',')
      interfaces.delete_if do |x|
        x =~ /^lo/
      end

      interfaces.each do |iface|
        if fact_on(host, "ipaddress_#{iface}").strip.empty?
          on(host, "ifup #{iface}", :accept_all_exit_codes => true)
        end
      end
    end
  end

  ssh_allow = <<-EOM
    include '::tcpwrappers'
    include '::iptables'

    tcpwrappers::allow { 'sshd':
      pattern => 'ALL'
    }

    iptables::listen::tcp_stateful { 'i_love_testing':
      order        => 8,
      trusted_nets => ['ALL'],
      dports       => 22
    }
  EOM

  let(:manifest) {
    <<-EOS
      include 'simp::server::yum'
      include 'simp::yum'

      Class['simp::server::yum'] -> Class['simp::yum']

      #{ssh_allow}
    EOS
  }

  let(:hieradata) {
    <<-EOM
---
simp_apache::rsync_server : '127.0.0.1'
simp_apache::rsync_web_root : false
simp_options::trusted_nets:
  - ALL

simp_options::rsync: false
simp_options::pki: true
simp_options::pki::source : '/etc/pki/simp-testing/pki'

simp_apache::rsync_server : '127.0.0.1'
simp_apache::rsync_web_root : false
simp_apache::ssl::sslverifyclient: none

simp::yum::local_simp_repos: true
simp::yum::local_repo_servers:
  - "%{::fqdn}"
    EOM
  }

  context 'with reliable test host' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do

      hosts.each do |host|

        host.install_package('createrepo')

        # Mock out the actual YUM repos
        repos = [
          '/var/www/yum/SIMP/x86_64',
          '/var/www/yum/CentOS/7/x86_64/Updates',
          '/var/www/yum/CentOS/6/x86_64/Updates'
        ]

        repos.each do |repo|
          on(host, "mkdir -p #{repo}")
          on(host, "cd #{repo}; createrepo .")
        end

        # Fix the SELinux contexts and permissions
        on(host, 'chmod -R go+rX /var/www')

        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)

        # This isn't something that we would expect Puppet to do based on how
        # we're creating the test repos
        on(host, 'chcon -R --reference=/var/www /var/www/yum')

        on(host, 'yum clean all')
        on(host, 'yum --disablerepo="*" --enablerepo="simp" list available > /dev/null')
      end
    end
  end
end
