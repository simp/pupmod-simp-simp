require 'spec_helper'

describe 'simp::nsswitch' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        if os_facts[:kernel] == 'windows'
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
        else
          context 'with default parameters' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::nsswitch') }
            it { is_expected.to create_file('nsswitch.conf').with_content(<<~EOM) }
              # This file is controlled by Puppet

              passwd:     files mymachines systemd
              shadow:     files
              group:      files mymachines systemd
              sudoers:    files
              hosts:      files mymachines dns myhostname
              bootparams: files
              ethers:     files
              netmasks:   files
              networks:   files
              protocols:  files
              rpc:        files
              services:   files
              netgroup:   files
              publickey:  files
              automount:  files
              aliases:    files
              EOM
          end

          context 'with sssd => true' do
            let(:params) { { sssd: true } }

            let(:content) do
              <<~EOM
              # This file is controlled by Puppet

              passwd:     files [!NOTFOUND=return] sss mymachines systemd
              shadow:     files [!NOTFOUND=return] sss
              group:      files [!NOTFOUND=return] sss mymachines systemd
              sudoers:    files sss
              hosts:      files mymachines dns myhostname
              bootparams: files
              ethers:     files
              netmasks:   files
              networks:   files
              protocols:  files
              rpc:        files
              services:   files
              netgroup:   files [!NOTFOUND=return] sss
              publickey:  files
              automount:  files
              aliases:    files
              EOM
            end

            it { is_expected.to create_file('nsswitch.conf').with_content(content) }
          end

          context 'with ldap => true' do
            let(:params) { { ldap: true } }

            it { is_expected.to create_file('nsswitch.conf').with_content(<<~EOM) }
              # This file is controlled by Puppet

              passwd:     files [!NOTFOUND=return] ldap mymachines systemd
              shadow:     files [!NOTFOUND=return] ldap
              group:      files [!NOTFOUND=return] ldap mymachines systemd
              sudoers:    files [!NOTFOUND=return] ldap
              hosts:      files mymachines dns myhostname
              bootparams: files
              ethers:     files
              netmasks:   files
              networks:   files
              protocols:  files
              rpc:        files
              services:   files
              netgroup:   files [!NOTFOUND=return] ldap
              publickey:  files
              automount:  files
              aliases:    files
              EOM
          end
        end
      end
    end
  end
end
