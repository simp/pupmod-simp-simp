require 'spec_helper'

describe 'simp::admin' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:puppet_settings] = {
            :ssldir => '/opt/puppet/somewhere/ssl'
          }
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::admin') }
          it { is_expected.to create_class('simp::sudoers') }
          it { is_expected.to create_sudo__alias__user('admins') }
          it { is_expected.to create_sudo__alias__user('auditors') }
          it { is_expected.to create_sudo__user_specification('admin_global').with({
            :user_list => ['%administrators'],
            :cmnd      => ['/usr/bin/sudosh'],
            :passwd    => false
          }) }
          it { is_expected.to create_sudo__user_specification('auditors').with({
            :user_list => ['%security'],
            :cmnd      => ['AUDIT'],
            :passwd    => false
          }) }
          if facts[:os][:release][:major].to_i >= 7
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
        end

        context 'with admin and auditor settings' do
          let(:params) {{
              :admin_group               => 'devs',
              :passwordless_admin_sudo   => false,
              :auditor_group             => 'auditors',
              :passwordless_auditor_sudo => false,
              :force_logged_shell        => false
          }}
          it { is_expected.to create_sudo__user_specification('admin_global').with({
            :user_list => ['%devs'],
            :cmnd      => ['ALL'],
            :passwd    => true
          }) }
          it { is_expected.to create_sudo__user_specification('auditors').with({
            :user_list => ['%auditors'],
            :cmnd      => ['AUDIT'],
            :passwd    => true
          }) }
        end

        context 'polkit settings' do
          if facts[:os][:release][:major].to_i >= 7
            it { is_expected.to create_polkit__authorization__rule('Set administrators group to a policykit administrator').with({
              :ensure => 'present',
              :priority => 10,
              :content => /unix-group:administrators/
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
            if facts[:os][:release][:major].to_i >= 7
              it { is_expected.to create_polkit__authorization__rule('Set coolkids group to a policykit administrator').with({
                :ensure => 'present',
                :priority => 10,
                :content => /unix-group:coolkids/
              }) }
            end
          end
        end

      end
    end
  end
end
