require 'spec_helper'

describe 'simp_yumrepo_gpgkeys' do
  describe 'signature validation' do
    it { is_expected.not_to eq(nil) }
    it { is_expected.to run.with_params().and_raise_error(Puppet::ParseError, /wrong number of arguments/i) }
    it { is_expected.to run.with_params('one').and_raise_error(Puppet::ParseError, /wrong number of arguments/i) }
    it { is_expected.to run.with_params('one', 'two', 'three').and_raise_error(Puppet::ParseError, /wrong number of arguments/i) }
    it { is_expected.to run.with_params(false, 'two').and_raise_error(Puppet::ParseError, /expects the first argument to be String/i) }
    it { is_expected.to run.with_params('one', 200).and_raise_error(Puppet::ParseError, /expects the second argument to be an array or string/i) }
  end

  let(:url) { 'https://YUM_SERVER/yum/SIMP' }
  let(:servers) { ['1.1.1.1', '2.2.2.2'] }
  let(:expected_output) {{
    'centos-6-x86_64' =>
      "https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-elasticsearch\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-grafana\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-6\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-elasticsearch\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-grafana\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-6",

    'centos-7-x86_64' =>
      "https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-elasticsearch\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-grafana\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-7\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-elasticsearch\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-grafana\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-7",

    'redhat-6-x86_64' =>
      "https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-elasticsearch\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-grafana\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-6\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-redhat-release\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-elasticsearch\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-grafana\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-6\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-redhat-release",

    'redhat-7-x86_64' =>
      "https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-elasticsearch\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-grafana\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-7\n" +
      "    https://1.1.1.1/yum/SIMP/GPGKEYS/RPM-GPG-KEY-redhat-release\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-elasticsearch\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-grafana\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-7\n" +
      "    https://2.2.2.2/yum/SIMP/GPGKEYS/RPM-GPG-KEY-redhat-release"
  }}

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        before :each do
          # SIMP's provided facts use symbols as keys, which are not accessible
          # in Puppet. See SIMP-2696
          structured_os = { 'name' => facts[:os][:name].to_s, 'release' => { 'major' => facts[:os][:release][:major].to_s } }
          Facter.stubs(:value).with('os').returns structured_os
        end

        let(:facts) { facts }
        it { is_expected.to run.with_params(url, servers).and_return( expected_output[os] ) }
      end
    end
  end

end
