require 'spec_helper'

describe 'simp::yum::repo::local_os_updates' do

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

      let(:facts) do
        os_facts
      end

      context 'with a single server name' do
        let(:params) {{ :servers => ['puppet.example.simp'] }}

        it { is_expected.to compile.with_all_deps }
        it {
          os_maj_rel  = facts[:os][:release][:major]
          os_name     = facts[:os][:name]
          os_yum_path =  "#{os_name}/#{os_maj_rel}/#{facts[:architecture]}"

          if os_name  == 'RedHat'
            gpgkey = "https://puppet.example.simp/yum/#{os_yum_path}/RPM-GPG-KEY-redhat-release"
          elsif os_name  == 'OracleLinux'
            gpgkey = "https://puppet.example.simp/yum/#{os_yum_path}/RPM-GPG-KEY-oracle"
          else
            gpgkey = "https://puppet.example.simp/yum/#{os_yum_path}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}"
          end

          is_expected.to contain_yumrepo('os_updates').with(
            :baseurl => "https://puppet.example.simp/yum/#{os_yum_path}/Updates",
            :gpgkey  => gpgkey
          )
        }
      end


      context 'with multiple servers and extra gpgkey URLs' do
        let(:params) {
          arbitrary_url = 'https://yum.test.simp:4433/repos/' +
                          "#{facts[:os][:name]}_#{facts[:os][:release][:major]}" +
                          "_#{facts[:architecture]}"
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
          os_yum_path =  "#{os_name}/#{os_maj_rel}/#{facts[:architecture]}"
          arbitrary_url = 'https://yum.test.simp:4433/repos/' +
                          "#{facts[:os][:name]}_#{facts[:os][:release][:major]}" +
                          "_#{facts[:architecture]}"

          gpg_prefixes = ['puppet.example.simp', '192.0.2.5']
            .map{|x| "https://#{x}/yum/#{os_yum_path}" }

          if os_name  == 'RedHat'
            gpgkey = gpg_prefixes.map{|x| "#{x}/RPM-GPG-KEY-redhat-release" }.join("\n    ")
          elsif os_name  == 'OracleLinux'
            gpgkey = gpg_prefixes.map{|x| "#{x}/RPM-GPG-KEY-oracle" }.join("\n    ")
          else
            gpgkey = gpg_prefixes.map{|x| "#{x}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}" }.join("\n    ")
          end
          gpgkey += "\n    #{arbitrary_url}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}"

          is_expected.to contain_yumrepo('os_updates').with(
            :baseurl => "https://puppet.example.simp/yum/#{os_yum_path}/Updates\n    " +
                        "https://192.0.2.5/yum/#{os_yum_path}/Updates\n    " +
                        arbitrary_url,
            :gpgkey  => gpgkey
          )
        }
      end

    end
  end
end
