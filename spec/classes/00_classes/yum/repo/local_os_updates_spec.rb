require 'spec_helper'

describe 'simp::yum::repo::local_os_updates' do

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      if os_facts[:kernel] == 'windows'
        it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows .+' is not supported/) }
        next
      end

      context 'with a single server name' do
        let(:params) {{ :servers => ['puppet.example.simp'] }}
        let(:os_name){ facts[:os][:name] }
        let(:os_maj_rel){ facts[:os][:release][:major] }

        it { is_expected.to compile.with_all_deps }



        it {
          os_yum_path =  "#{os_name}/#{os_maj_rel}/#{facts[:architecture]}"
          gpgkey_path =  "SIMP/GPGKEYS"

          if os_name  == 'RedHat'
            gpgkey = "https://puppet.example.simp/yum/#{gpgkey_path}/RPM-GPG-KEY-redhat-release"
          elsif os_name  == 'OracleLinux'
            gpgkey = "https://puppet.example.simp/yum/#{gpgkey_path}/RPM-GPG-KEY-oracle"
          elsif os_name  == 'Rocky'
            gpgkey = "https://puppet.example.simp/yum/#{gpgkey_path}/RPM-GPG-KEY-rockyofficial"
          else
            gpgkey = "https://puppet.example.simp/yum/#{gpgkey_path}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}"
          end

          if os_maj_rel <= '7'

            is_expected.to contain_yumrepo('os_updates').with(
              :baseurl => "https://puppet.example.simp/yum/#{os_yum_path}/Updates",
              :gpgkey  => gpgkey
            )
          else
            is_expected.to contain_yumrepo('local_baseos').with(
              :baseurl => "https://puppet.example.simp/yum/#{os_yum_path}/BaseOS",
              :gpgkey  => gpgkey
            )

            is_expected.to contain_yumrepo('local_appstream').with(
              :baseurl => "https://puppet.example.simp/yum/#{os_yum_path}/AppStream",
              :gpgkey  => gpgkey
            )
          end
        }

        context 'with relative_repo_path = x/y/z and relative_gpgkey_path set to my/gpgkeys' do
          let(:params){super().merge( { relative_repo_path: 'x/y/z', relative_gpgkey_path: 'my/gpgkeys' })}
          it { is_expected.to compile.with_all_deps }
          it {
            gpgkey_path = 'my/gpgkeys'
            if os_name  == 'RedHat'
              gpgkey = "https://puppet.example.simp/yum/#{gpgkey_path}/RPM-GPG-KEY-redhat-release"
            elsif os_name  == 'OracleLinux'
              gpgkey = "https://puppet.example.simp/yum/#{gpgkey_path}/RPM-GPG-KEY-oracle"
            elsif os_name  == 'Rocky'
              gpgkey = "https://puppet.example.simp/yum/#{gpgkey_path}/RPM-GPG-KEY-rockyofficial"
            else
              #it should be CentOS.
              gpgkey = "https://puppet.example.simp/yum/#{gpgkey_path}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}"
            end

            if os_maj_rel <= '7'
              is_expected.to contain_yumrepo('os_updates').with(
                :baseurl => "https://puppet.example.simp/yum/x/y/z/Updates",
                :gpgkey  => gpgkey
              )
            else
              is_expected.to contain_yumrepo('local_baseos').with(
                :baseurl => "https://puppet.example.simp/yum/x/y/z/BaseOS",
                :gpgkey  => gpgkey
              )

              is_expected.to contain_yumrepo('local_appstream').with(
                :baseurl => "https://puppet.example.simp/yum/x/y/z/AppStream",
                :gpgkey  => gpgkey
              )
            end
          }
        end
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
          gpgkey_path = "SIMP/GPGKEYS"
          arbitrary_url = 'https://yum.test.simp:4433/repos/' +
                          "#{facts[:os][:name]}_#{facts[:os][:release][:major]}" +
                          "_#{facts[:architecture]}"

          gpg_prefixes = ['puppet.example.simp', '192.0.2.5']
            .map{|x| "https://#{x}/yum/#{gpgkey_path}" }

          if os_name  == 'RedHat'
            gpgkey = gpg_prefixes.map{|x| "#{x}/RPM-GPG-KEY-redhat-release" }.join("\n    ")
          elsif os_name  == 'OracleLinux'
            gpgkey = gpg_prefixes.map{|x| "#{x}/RPM-GPG-KEY-oracle" }.join("\n    ")
          elsif os_name  == 'Rocky'
            gpgkey = gpg_prefixes.map{|x| "#{x}/RPM-GPG-KEY-rockyofficial" }.join("\n    ")
          else
            gpgkey = gpg_prefixes.map{|x| "#{x}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}" }.join("\n    ")
          end
          gpgkey += "\n    #{arbitrary_url}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}"

          if os_maj_rel <= '7'
            is_expected.to contain_yumrepo('os_updates').with(
              :baseurl => "https://puppet.example.simp/yum/#{os_yum_path}/Updates\n    " +
                          "https://192.0.2.5/yum/#{os_yum_path}/Updates\n    " +
                          arbitrary_url,
              :gpgkey  => gpgkey
            )
          else
            is_expected.to contain_yumrepo('local_baseos').with(
              :baseurl => "https://puppet.example.simp/yum/#{os_yum_path}/BaseOS\n    " +
                          "https://192.0.2.5/yum/#{os_yum_path}/BaseOS\n    " +
                          arbitrary_url,
              :gpgkey  => gpgkey
            )
            is_expected.to contain_yumrepo('local_appstream').with(
              :baseurl => "https://puppet.example.simp/yum/#{os_yum_path}/AppStream\n    " +
                          "https://192.0.2.5/yum/#{os_yum_path}/AppStream\n    " +
                          arbitrary_url,
              :gpgkey  => gpgkey
            )
          end

        }
      end

      context 'with baseurl and gpgkey overrides' do
        # For EL7 and earlier,  setting 'baseurl' and 'gpgkey'
        # directly should result in exactly the string that was specified
        #  For EL8 it will add the two repos with BaseOS and AppStream appended
        let(:params) {{
            servers: ['puppet.example.simp'],
            baseurl: 'https://yum.test1.simp/yum/foobar',
            gpgkey:  'https://yum.test2.simp/yum/foobar/GPGKEYS/RPM-GPG-KEY-CentOS-7',
        }}

        it { is_expected.to compile.with_all_deps }
        if os_facts[:os][:release][:major] <= '7'
          it {
            is_expected.to contain_yumrepo('os_updates').with(
              :baseurl => 'https://yum.test1.simp/yum/foobar',
              :gpgkey  => 'https://yum.test2.simp/yum/foobar/GPGKEYS/RPM-GPG-KEY-CentOS-7',
            )
          }
        else
          it {
            is_expected.to contain_yumrepo('local_baseos').with(
              :baseurl => 'https://yum.test1.simp/yum/foobar/BaseOS',
              :gpgkey  => 'https://yum.test2.simp/yum/foobar/GPGKEYS/RPM-GPG-KEY-CentOS-7',
            )
          }

          it {
            is_expected.to contain_yumrepo('local_appstream').with(
              :baseurl => 'https://yum.test1.simp/yum/foobar/AppStream',
              :gpgkey  => 'https://yum.test2.simp/yum/foobar/GPGKEYS/RPM-GPG-KEY-CentOS-7',
            )
          }
        end
      end
    end
  end
end
