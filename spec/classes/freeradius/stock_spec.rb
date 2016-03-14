require 'spec_helper'

describe 'simp::freeradius::stock' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          if ['RedHat','CentOS'].include?(facts[:operatingsystem]) && facts[:operatingsystemmajrelease].to_s < '7'
            facts[:apache_version] = '2.2'
            facts[:grub_version] = '0.9'
            facts[:init_systems] = ['rc','sysv','upstart']
          else
            facts[:apache_version] = '2.4'
            facts[:grub_version] = '2.0~beta'
            facts[:init_systems] = ['rc','sysv','systemd']
          end

          facts[:selinux_current_mode] = 'enforcing'

          facts
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('freeradius::users') }
        it { is_expected.to contain_class('freeradius::conf::client') }
        it { is_expected.to contain_class('freeradius::conf') }

        # Check to ensure the client is added
        it { is_expected.to create_file('/etc/raddb/conf/clients/default.conf').with_content(/ipaddr = 127.0.0.1/) }

        # Check to ensure that the default_auth listen is added
        it { is_expected.to create_file('/etc/raddb/conf/listen.inc/default_auth').with_content(/type = auth/) }

        # Check to ensure default users are added (default_ppp, default_cslip, default_slip)
        it { is_expected.to create_file('/etc/raddb/users.inc/100.default_ppp').with_content(/Framed-Protocol = PPP/) }
        it { is_expected.to create_file('/etc/raddb/users.inc/100.default_cslip').with_content(/Hint == "CSLIP"/) }
        it { is_expected.to create_file('/etc/raddb/users.inc/100.default_slip').with_content(/Hint == "SLIP"/) }
      end
    end
  end
end
