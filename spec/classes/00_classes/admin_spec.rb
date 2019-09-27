require 'spec_helper'

describe 'simp::admin' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        if os_facts[:kernel] == 'windows'
          let(:facts) { os_facts }
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/'windows .+' is not supported/) }
        else
          let(:facts) do
            _facts = Marshal.load(Marshal.dump(os_facts))

            _facts[:puppet_settings] = {
              :main => {
                :ssldir => '/opt/puppet/somewhere/ssl'
              }
            }

            _facts
          end

          context 'with default parameters' do
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_class('simp::admin') }
            it { is_expected.to create_class('simp::sudoers') }
            it { is_expected.to create_sudo__alias__user('admins') }
            it { is_expected.to create_sudo__alias__user('auditors') }
            it { is_expected.to create_file('/etc/profile.d/sudosh2.sh').with_ensure('absent') }
            it { is_expected.to create_class('tlog::rec_session') }
            it { is_expected.to create_sudo__user_specification('admin global').with({
              :user_list => ['%administrators'],
              :cmnd      => ['/bin/su - root'],
              :passwd    => false
            }) }
            it { is_expected.to create_sudo__user_specification('auditors').with({
              :user_list => ['%security'],
              :cmnd      => ['AUDIT'],
              :passwd    => false
            }) }
            it { is_expected.to create_sudo__user_specification('admin clean puppet certs').with({
              :user_list => ['%administrators'],
              :cmnd      => ['/bin/rm -rf /opt/puppet/somewhere/ssl'],
              :passwd    => false
            }) }
            if os_facts[:os][:release][:major].to_i >= 7
              it { is_expected.to create_polkit__authorization__rule('Set administrators group to a policykit administrator').with({
                :ensure => 'present',
                :priority => 10,
                :content => <<-EOF
polkit.addAdminRule(function(action, subject) {
  return ["unix-group:administrators"];
});
                EOF
              }) }
            end

            it { is_expected.to_not create_selinux_login('%administrators') }
          end

          context 'when setting tlog as the logged shell' do
            let(:params) {{
              :logged_shell => 'tlog'
            }}

            it { is_expected.to create_class('tlog::rec_session') }
            it { is_expected.to_not create_class('sudosh') }

            it { is_expected.to create_sudo__user_specification('admin global').with({
              :user_list => ['%administrators'],
              :cmnd      => ['/bin/su - root'],
              :passwd    => false
            }) }
          end

          context 'when setting sudosh as the logged shell' do
            let(:params) {{
              :logged_shell => 'sudosh'
            }}

            it { is_expected.to create_class('sudosh') }
            it { is_expected.to_not create_class('tlog::rec_session') }

            it { is_expected.to create_sudo__user_specification('admin global').with({
              :user_list => ['%administrators'],
              :cmnd      => ['/usr/bin/sudosh'],
              :passwd    => false
            }) }
          end

          context 'with admin and auditor settings' do
            let(:params) {{
                :admin_group               => 'devs',
                :passwordless_admin_sudo   => false,
                :auditor_group             => 'auditors',
                :passwordless_auditor_sudo => false,
                :force_logged_shell        => false
            }}
            it { is_expected.to create_sudo__user_specification('admin global').with({
              :user_list => ['%devs'],
              :cmnd      => ['/bin/su - root'],
              :passwd    => true
            }) }
            it { is_expected.to create_sudo__user_specification('auditors').with({
              :user_list => ['%auditors'],
              :cmnd      => ['AUDIT'],
              :passwd    => true
            }) }
          end

          context "when $facts['puppet_settings'] isn't available" do
            let(:facts) do
              _facts = Marshal.load(Marshal.dump(os_facts))
              _facts[:puppet_settings] = nil

              _facts
            end
            it { is_expected.to create_sudo__user_specification('admin clean puppet certs').with({
              :user_list => ['%administrators'],
              :cmnd      => ['/bin/rm -rf /etc/puppetlabs/puppet/ssl'],
              :passwd    => false
            }) }
          end

          context 'polkit settings' do
            if os_facts[:os][:release][:major].to_i >= 7
              it { is_expected.to create_polkit__authorization__rule('Set administrators group to a policykit administrator').with({
                :ensure   => 'present',
                :priority => 10,
                :content  => /unix-group:administrators/
              }) }
            end

            context 'with set_polkit_admin_group => false' do
              let(:params) {{ :set_polkit_admin_group => false }}
              it { is_expected.to create_polkit__authorization__rule('Set administrators group to a policykit administrator').with({
                :ensure => 'absent',
              }) }
            end

            context 'with admin_group => coolkids' do
              let(:params) {{ :admin_group => 'coolkids' }}
              if os_facts[:os][:release][:major].to_i >= 7
                it { is_expected.to create_polkit__authorization__rule('Set coolkids group to a policykit administrator').with({
                  :ensure   => 'present',
                  :priority => 10,
                  :content  => /unix-group:coolkids/
                }) }
              end
            end
          end

          context 'selinux settings' do
            let(:params) {{ :set_selinux_login => true }}

            it { is_expected.to create_selinux_login('%administrators').with({
                :seuser => 'staff_u',
                :mls_range => 's0-s0:c0.c1023'
              })
            }
          end
        end
      end
    end
  end
end
