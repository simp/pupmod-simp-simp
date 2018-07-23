require 'spec_helper'

describe 'simp::yum::repo::local_simp' do

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

      let(:facts) do
        os_facts
      end

      let(:base_gpgkeys){
        [
          'RPM-GPG-KEY-puppet',
          'RPM-GPG-KEY-puppetlabs',
          'RPM-GPG-KEY-SIMP',
          'RPM-GPG-KEY-elasticsearch',
          'RPM-GPG-KEY-grafana-legacy',
          'RPM-GPG-KEY-grafana',
          'RPM-GPG-KEY-PGDG-94',
          'RPM-GPG-KEY-PGDG-96'
        ]
      }
      let(:other_gpgkeys){
        {
           'RedHat-6'      => ['RPM-GPG-KEY-EPEL-6','RPM-GPG-KEY-redhat-release'],
           'OracleLinux-6' => ['RPM-GPG-KEY-EPEL-6','RPM-GPG-KEY-oracle'],
           'CentOS-6'      => ['RPM-GPG-KEY-EPEL-6'],
           'RedHat-7'      => ['RPM-GPG-KEY-EPEL-7','RPM-GPG-KEY-redhat-release'],
           'OracleLinux-7' => ['RPM-GPG-KEY-EPEL-7','RPM-GPG-KEY-oracle'],
           'CentOS-7'      => ['RPM-GPG-KEY-EPEL-7']
        }
      }

      context 'with a single server name' do
        let(:params) {{ :servers => ['puppet.example.simp'] }}

        it { is_expected.to compile.with_all_deps }
        it {
          os_yum_path =  'SIMP'
          os_baseurl  = "#{os_yum_path}/#{facts[:architecture]}"
          os_gpgkey   = "#{os_yum_path}/GPGKEYS"
          _keys = base_gpgkeys + other_gpgkeys.fetch( "#{facts[:os][:name]}-#{facts[:os][:release][:major]}" )
          gpgkey = _keys.map{|x| "https://puppet.example.simp/yum/#{os_gpgkey}/#{x}"}.join("\n    ")

          is_expected.to contain_yumrepo('simp').with(
            :baseurl => "https://puppet.example.simp/yum/#{os_baseurl}",
            :gpgkey  => gpgkey,
          )
        }
      end


      context 'with multiple servers and extra gpgkey URLs' do
        let(:params) {
          arbitrary_url = 'https://yum.test.simp:4433/repos/' +
                          "SIMP/6/#{facts[:architecture]}"
          {
          :servers => [
            'puppet.example.simp',
            '192.0.2.5',
            arbitrary_url,
          ],
          :extra_gpgkey_urls => [
            "#{arbitrary_url}/RPM-GPG-KEY-#{facts[:os][:name]}-#{facts[:os][:release][:major]}"
          ]
        }}

        it { is_expected.to compile.with_all_deps }
        it {
          os_maj_rel  = facts[:os][:release][:major]
          os_name     = facts[:os][:name]
          os_yum_path =  'SIMP'
          os_baseurl  = "#{os_yum_path}/#{facts[:architecture]}"
          arbitrary_url = 'https://yum.test.simp:4433/repos/' +
                          "SIMP/6/#{facts[:architecture]}"

          os_baseurl  = "#{os_yum_path}/#{facts[:architecture]}"
          os_gpgkey   = "#{os_yum_path}/GPGKEYS"
          _keys = base_gpgkeys + other_gpgkeys.fetch( "#{facts[:os][:name]}-#{facts[:os][:release][:major]}" )
          _gpgkey = ['puppet.example.simp', '192.0.2.5']
            .map{ |y|  _keys.map{|x| "https://#{y}/yum/#{os_gpgkey}/#{x}"} }
          gpgkey = _gpgkey.join("\n    ")
          gpgkey += "\n    #{arbitrary_url}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}"

          is_expected.to contain_yumrepo('simp').with(
            :baseurl => "https://puppet.example.simp/yum/#{os_baseurl}\n    " +
                        "https://192.0.2.5/yum/#{os_baseurl}\n    " +
                        arbitrary_url,
            :gpgkey  => gpgkey
          )
        }
      end

    end
  end
end
