require 'spec_helper_acceptance'

parallel = { :run_in_parallel => ['yes', 'true', 'on'].include?(ENV['BEAKER_SIMP_parallel']) }

test_name 'simp yum configuration'

describe 'simp yum configuration' do
  let(:manifest) {
    <<-EOS
      include 'simp'
      include 'pupmod'
      include 'simp::yum::repo::internet_simp_server'
      include 'simp::yum::repo::internet_simp_dependencies'
    EOS
  }

  context 'add repos to system' do
    hosts.each do |host|
      it 'should set the SIMP version' do
        on(host, 'echo 6.0.0-0.el7 > /etc/simp/simp.version')
      end
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end
      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
      describe file('/etc/yum.repos.d/simp-project_6_X.repo') do
        its(:content) { should match(/https:\/\/packagecloud.io\/simp-project\/6_X\/el\/[67]\/x86_64/) }
      end
      describe file('/etc/yum.repos.d/simp-project_6_X_Dependencies.repo') do
        its(:content) { should match(/https:\/\/packagecloud.io\/simp-project\/6_X_Dependencies\/el\/[67]\/x86_64/) }
      end
    end
  end

  context 'the contents of the simp repo' do
    it 'should contain some simp server packages' do
      packages = [
        'simp-adapter-pe',
        'simp-adapter',
        'simp',
        'pupmod-simp-simp',
        'pupmod-simp-simplib',
      ]
      block_on(hosts, parallel) do |host|
        on(host, 'yum clean all')
        packages.each do |package|
          on(host, "yum --disablerepo=* --enablerepo='simp-project_6_X' list | grep #{package} ")
        end
      end
    end
  end

  context 'the contents of the simp dependencies repo' do
    it 'should contain some simp server packages' do
      packages = [
        'haveged',
        'simp-ppolicy-check-password',
        'logstash',
        'chkrootkit'
      ]
      block_on(hosts, parallel) do |host|
        on(host, 'yum clean all')
        packages.each do |package|
          on(host, "yum --disablerepo=* --enablerepo='simp-project_6_X_Dependencies' list | grep #{package} ")
        end
      end
    end
  end
end
