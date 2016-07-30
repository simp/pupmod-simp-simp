require 'spec_helper_acceptance'

test_name 'simp::yum class'

describe 'simp::yum class' do

  ssh_allow = <<-EOM
    include '::tcpwrappers'
    include '::iptables'

    tcpwrappers::allow { 'sshd':
      pattern => 'ALL'
    }

    iptables::add_tcp_stateful_listen { 'i_love_testing':
      order => '8',
      client_nets => 'ALL',
      dports => '22'
    }
  EOM

  let(:manifest) {
    <<-EOS
      include 'simp::yum_server'
      include 'simp::yum'

      Class['simp::yum_server'] -> Class['simp::yum']

      #{ssh_allow}
    EOS
  }

  let(:hieradata) {
    <<-EOM
---
client_nets:
  - ALL

pki_dir : '/etc/pki/simp-testing/pki'
pki::private_key_source : "file://%{hiera('pki_dir')}/private/%{::fqdn}.pem"
pki::public_key_source : "file://%{hiera('pki_dir')}/public/%{::fqdn}.pub"
pki::cacerts_sources :
  - "file://%{hiera('pki_dir')}/cacerts"

apache::rsync_server : '127.0.0.1'
apache::rsync_web_root : false
apache::ssl::sslverifyclient : 'none'

simp::yum::servers:
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
          on(host, "chmod -R go+rX /var/www")
        end

        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)

        on(host, 'yum clean all')
        on(host, 'yum --disablerepo="*" --enablerepo="simp" list > /dev/null')
      end
    end
  end
end
