require 'spec_helper'

describe 'simp::yum::repo::local_simp' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:base_gpgkeys) do
        [
          'RPM-GPG-KEY-puppet-20250406',
          'RPM-GPG-KEY-puppet',
          'RPM-GPG-KEY-puppetlabs',
          'RPM-GPG-KEY-SIMP-6',
          'RPM-GPG-KEY-PGDG-94',
        ]
      end
      let(:other_gpgkeys) do
        {
          'RedHat-7' => ['RPM-GPG-KEY-EPEL-7', 'RPM-GPG-KEY-redhat-release'],
           'OracleLinux-7' => ['RPM-GPG-KEY-EPEL-7', 'RPM-GPG-KEY-oracle'],
           'CentOS-7'      => ['RPM-GPG-KEY-EPEL-7', 'RPM-GPG-KEY-CentOS-7'],
           'RedHat-8'      => ['RPM-GPG-KEY-EPEL-8', 'RPM-GPG-KEY-redhat-release'],
           'OracleLinux-8' => ['RPM-GPG-KEY-EPEL-8', 'RPM-GPG-KEY-oracle'],
           'CentOS-8'      => ['RPM-GPG-KEY-EPEL-8', 'RPM-GPG-KEY-CentOS-8'],
           'Rocky-8'       => ['RPM-GPG-KEY-EPEL-8', 'RPM-GPG-KEY-rockyofficial'],
           'AlmaLinux-8'   => ['RPM-GPG-KEY-EPEL-8', 'RPM-GPG-KEY-AlmaLinux'],
        }
      end

      if os_facts[:kernel] == 'windows'
        it {
          expect { is_expected.to compile.with_all_deps }.to raise_error(
            %r{'windows .+' is not supported|There are no Yumrepo GPG keys for OS 'windows'},
          )
        }
        next
      end

      context 'with a single server name' do
        let(:params) { { servers: ['puppet.example.simp'] } }
        let(:os_yum_path) { "SIMP/#{facts[:os][:name]}/#{facts[:os][:release][:major]}" }
        let(:os_baseurl) { "#{os_yum_path}/#{facts[:os][:architecture]}" }
        let(:os_gpgkey) { 'SIMP/GPGKEYS' }

        it { is_expected.to compile.with_all_deps }
        it {
          keys = base_gpgkeys + other_gpgkeys.fetch("#{facts[:os][:name]}-#{facts[:os][:release][:major]}")
          gpgkey = keys.map { |x| "https://puppet.example.simp/yum/#{os_gpgkey}/#{x}" }.join("\n    ")

          baseurl = "https://puppet.example.simp/yum/#{os_baseurl}"
          if facts[:package_provider] == 'dnf'
            baseurl = "#{baseurl}/SIMP"
          end

          is_expected.to contain_yumrepo('simp').with(
            baseurl: baseurl,
            gpgkey: gpgkey,
          )
        }

        context 'with relative_repo_path = x/y/z and relative_gpgkey_path x/y/z/GPGKEYS' do
          let(:params) do
            super().merge(
              relative_repo_path: 'x/y/z',
              relative_gpgkey_path: 'x/y/z/GPGKEYS',
            )
          end

          it { is_expected.to compile.with_all_deps }
          it {
            keys = base_gpgkeys + other_gpgkeys.fetch("#{facts[:os][:name]}-#{facts[:os][:release][:major]}")
            gpgkey = keys.map { |x| "https://puppet.example.simp/yum/x/y/z/GPGKEYS/#{x}" }.join("\n    ")

            baseurl = 'https://puppet.example.simp/yum/x/y/z/x86_64'
            if facts[:package_provider] == 'dnf'
              baseurl = "#{baseurl}/SIMP"
            end

            is_expected.to contain_yumrepo('simp').with(
              baseurl: baseurl,
              gpgkey: gpgkey,
            )
          }
        end
      end

      context 'with multiple servers and extra gpgkey URLs' do
        let(:params) do
          arbitrary_url = 'https://yum.test.simp:4433/repos/' \
                          "SIMP/6/#{facts[:os][:architecture]}"
          {
            servers: [
              'puppet.example.simp',
              '192.0.2.5',
              arbitrary_url,
            ],
            extra_gpgkey_urls: [
              "#{arbitrary_url}/RPM-GPG-KEY-#{facts[:os][:name]}-#{facts[:os][:release][:major]}",
            ],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          os_maj_rel  = facts[:os][:release][:major]
          os_name     = facts[:os][:name]
          os_yum_path = "SIMP/#{os_name}/#{os_maj_rel}"
          arbitrary_url = 'https://yum.test.simp:4433/repos/' \
                          "SIMP/6/#{facts[:os][:architecture]}"

          os_baseurl  = "#{os_yum_path}/#{facts[:os][:architecture]}"
          os_gpgkey   = 'SIMP/GPGKEYS'
          keys = base_gpgkeys + other_gpgkeys.fetch("#{facts[:os][:name]}-#{facts[:os][:release][:major]}")
          gpgkey = ['puppet.example.simp', '192.0.2.5']
                   .map { |y| keys.map { |x| "https://#{y}/yum/#{os_gpgkey}/#{x}" } }
                   .join("\n    ")
          gpgkey += "\n    #{arbitrary_url}/RPM-GPG-KEY-#{os_name}-#{os_maj_rel}"

          arbitrary_baseurl = arbitrary_url.dup
          if facts[:package_provider] == 'dnf'
            arbitrary_baseurl = "#{arbitrary_url}/SIMP"
          end

          is_expected.to contain_yumrepo('simp').with(
            baseurl: "https://puppet.example.simp/yum/#{os_baseurl}\n    " \
                        "https://192.0.2.5/yum/#{os_baseurl}\n    " +
                        arbitrary_baseurl,
            gpgkey: gpgkey,
          )
        }
      end

      context 'with baseurl and gpgkey overrides' do
        # No matter what OS we're testing, setting 'baseurl' and 'gpgkey'
        # directly should result in exactly the string that was specified
        # (in this case, repos for CentOS 8).
        let(:gpgkey_string) do
          [
            'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-EPEL-8',
            'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-PGDG-94',
            'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-SIMP-6',
            'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppet',
            'https://yum.test.simp/yum/SIMP/GPGKEYS/RPM-GPG-KEY-puppetlabs',
          ].join("\n    ")
        end
        let(:params) do
          {
            servers: ['puppet.example.simp'],
            baseurl: 'https://yum.test.simp/yum/CentOS/8/x86_64/Updates',
            gpgkey:  gpgkey_string,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          baseurl = 'https://yum.test.simp/yum/CentOS/8/x86_64/Updates'
          if facts[:package_provider] == 'dnf'
            baseurl = "#{baseurl}/SIMP"
          end

          is_expected.to contain_yumrepo('simp').with(
            baseurl: baseurl,
            gpgkey: gpgkey_string,
          )
        }
      end
    end
  end
end
