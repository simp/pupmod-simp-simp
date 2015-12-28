require 'spec_helper_acceptance'

test_name 'simp::yum class'

describe 'simp::yum class' do
  let(:manifest) {
    <<-EOS
      include 'simp::yum'
    EOS
  }

  context 'with reliable test host' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do

      hosts.each do |host|
        fail "You must specify 'simp_update_url' in your nodeset!" unless host['simp_update_url']

        hieradata = <<-EOS
          'simp::yum::servers' :
            - 'dl.bintray.com'
          'simp::yum::os_update_url' : 'http://mirror.centos.org/centos/$releasever/updates/$basearch'
          'simp::yum::os_gpg_url' : 'http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-$releasever'
          'simp::yum::simp_update_url' : '#{host['simp_update_url']}'
          'simp::yum::simp_gpg_url' : 'https://raw.githubusercontent.com/NationalSecurityAgency/SIMP/master/GPGKEYS/RPM-GPG-KEY-SIMP'
        EOS

        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)

        on(host, 'yum clean all')
        on(host, 'yum --disablerepo="*" --enablerepo="os_updates" list > /dev/null')
        on(host, 'yum --disablerepo="*" --enablerepo="simp" list > /dev/null')
      end
    end
  end
end
