# Can't run this until we get access to server_facts
require 'spec_helper'

describe 'simp::server::yum' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        if facts[:operatingsystemmajrelease].to_s < '7'
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

      context 'base' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_simp_apache__site('yum') }
      end
    end
  end
end
