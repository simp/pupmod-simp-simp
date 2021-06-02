require 'spec_helper_acceptance'

parallel = { :run_in_parallel => ['yes', 'true', 'on'].include?(ENV['BEAKER_SIMP_parallel']) }

test_name 'simp yum configuration'

describe 'simp yum configuration' do
  let(:manifest) {
    <<-EOS
      include 'simp'
      include 'pupmod'
      include 'simp::yum::repo::internet_simp'
    EOS
  }

  context 'add repos to system' do
    hosts.each do |host|
      it 'should set the SIMP version' do
        # simplib::simp_version() needs either this file or an installed simp RPM
        # in order to return a SIMP version!
        on(host, 'echo 6.4.0-0.el7 > /etc/simp/simp.version')
      end
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end
      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should install simp-release-community package' do
        result = on(host, 'puppet resource package simp-release-community')
        expect(result.stdout).to_not match(/purged/)
      end
    end
  end

  context 'the contents of the simp internet repos' do
    it 'should contain some simp server packages' do
      packages = [
        'simp-adapter',
        'simp',
        'pupmod-simp-simp',
        'pupmod-simp-simplib',
      ]
      block_on(hosts, parallel) do |host|
        on(host, 'yum clean all')
        packages.each do |package|
          # FIXME Workaround until download.simp-project.com repos are populated for EL8
          begin
            on(host, "yum --disablerepo=* --enablerepo='simp-community-simp' list | grep #{package} ")
          rescue Beaker::Host::CommandFailure => e
            skip "#{self.class.description} failed => #{e}"
          end
        end
      end
    end

    it 'should contain some simp dependency packages' do
      packages = {
        'haveged'      => 'simp-community-epel',
        'postgresql96' => 'simp-community-postgresql',
        'puppet-agent' => 'simp-community-puppet'
      }
      block_on(hosts, parallel) do |host|
        on(host, 'yum clean all')
        packages.each do |package,repo|
          # FIXME Workaround until download.simp-project.com repos are populated for EL8
          begin
            on(host, "yum --disablerepo=* --enablerepo='#{repo}' list | grep #{package} ")
          rescue Beaker::Host::CommandFailure => e
            skip "#{self.class.description} failed => #{e}"
          end
        end
      end
    end
  end
end
