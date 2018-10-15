require 'spec_helper'

describe 'simp::nsswitch' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::nsswitch') }
          it { is_expected.to create_file('nsswitch.conf').with_content(<<-EOM) }
# This file is controlled by Puppet

passwd:     files
shadow:     files
group:      files
sudoers:    files
hosts:      files dns
bootparams: nisplus [NOTFOUND=return] files
ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files
netgroup:   files
publickey:  nisplus
automount:  files nisplus
aliases:    files nisplus
EOM
        end

        context 'with sssd => true' do
          let(:params) {{ :sssd => true }}
          it { is_expected.to create_file('nsswitch.conf').with_content(<<-EOM) }
# This file is controlled by Puppet

passwd:     files [!NOTFOUND=return] sss
shadow:     files [!NOTFOUND=return] sss
group:      files [!NOTFOUND=return] sss
sudoers:    files [!NOTFOUND=return] sss
hosts:      files dns
bootparams: nisplus [NOTFOUND=return] files
ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files
netgroup:   files [!NOTFOUND=return] sss
publickey:  nisplus
automount:  files nisplus
aliases:    files nisplus
EOM
        end

        context 'with ldap => true' do
          let(:params) {{ :ldap => true }}
          it { is_expected.to create_file('nsswitch.conf').with_content(<<-EOM) }
# This file is controlled by Puppet

passwd:     files [!NOTFOUND=return] ldap
shadow:     files [!NOTFOUND=return] ldap
group:      files [!NOTFOUND=return] ldap
sudoers:    files [!NOTFOUND=return] ldap
hosts:      files dns
bootparams: nisplus [NOTFOUND=return] files
ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files
netgroup:   files [!NOTFOUND=return] ldap
publickey:  nisplus
automount:  files nisplus
aliases:    files nisplus
EOM
        end

      end
    end
  end
end
