require 'spec_helper_acceptance'

test_name 'simp yum configuration'

describe 'simp yum configuration' do
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
      include 'simp::version'
      include 'simp::yum::repo::internet_simp_server'
      include 'simp::yum::repo::internet_simp_dependencies'

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
    EOM
  }

  context 'add repos to system' do
    hosts.each do |host|
      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end
      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
      describe file('/etc/yum.repos.d/simp-project_6.X.repo') do
        its(:content) { should match %r{https://packagecloud.io/simp-project/6.X/el/[67]/x86_64/} }
      end
      describe file('/etc/yum.repos.d/simp-project_6.X_Dependencies.repo') do
        its(:content) { should match %r{https://packagecloud.io/simp-project/6.X_Dependencies/el/[67]/x86_64/} }
      end
    end
  end

  context 'the contents of the simp repo' do
    it 'should contain some simp server packages' do
      packages = [
        'simp-adapter-pe',
        'simp-adapter-foss',
        'simp',
        'pupmod-simp-simp',
        'pupmod-simp-simplib',
      ]
      hosts.each do |host|
        on(host, 'yum clean all')
        packages.each do |package|
          on(host, "yum --disablerepo=* --enablerepo='simp-project_6.X' list available | grep #{package} ")
        end
      end
    end
  end

  context 'the contents of the simp dependencies repo' do
    it 'should contain some simp server packages' do
      packages = [
        'sudosh2',
        'haveged',
        'simp-ppolicy-check-password',
        'logstash',
        'chkrootkit'
      ]
      hosts.each do |host|
        on(host, 'yum clean all')
        packages.each do |package|
          on(host, "yum --disablerepo=* --enablerepo='simp-project_6.X_Dependencies' list available | grep #{package} ")
        end
      end
    end
  end
end
