require 'spec_helper'

describe 'simp::nsswitch' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters on EL 6' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::nsswitch') }
          if facts[:os][:release][:major] == 6 then
            it { is_expected.to create_file('/etc/nsswitch.conf').with_content(<<-EOM) }
# This file is controlled by Puppet

passwd:     files
shadow:     files
group:      files
sudoers:    files
hosts:      files myhostname dns
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
          else
            it { is_expected.to create_file('/etc/nsswitch.conf').with_content(<<-EOM) }
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
        end

        context 'with sssd => true' do
          let(:params) {{ :sssd => true }}
          if facts[:os][:release][:major] == 6 then
            it { is_expected.to create_file('/etc/nsswitch.conf').with_content(<<-EOM) }
# This file is controlled by Puppet

passwd:     files [!NOTFOUND=return] sss
shadow:     files [!NOTFOUND=return] sss
group:      files [!NOTFOUND=return] sss
sudoers:    files [!NOTFOUND=return] sss
hosts:      files myhostname dns
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
          else
            it { is_expected.to create_file('/etc/nsswitch.conf').with_content(<<-EOM) }
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
        end

        context 'with ldap => true' do
          let(:params) {{ :ldap => true }}
          if facts[:os][:release][:major] == 6 then
            it { is_expected.to create_file('/etc/nsswitch.conf').with_content(<<-EOM) }
# This file is controlled by Puppet

passwd:     files [!NOTFOUND=return] ldap
shadow:     files [!NOTFOUND=return] ldap
group:      files [!NOTFOUND=return] ldap
sudoers:    files [!NOTFOUND=return] ldap
hosts:      files myhostname dns
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
          else
            it { is_expected.to create_file('/etc/nsswitch.conf').with_content(<<-EOM) }
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
end
