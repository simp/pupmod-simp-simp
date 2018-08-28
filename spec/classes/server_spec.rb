require 'spec_helper'

describe 'simp::server' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:puppet_settings] = {
            'main' => {
              'ssldir' => '/opt/puppetlabs/puppet/vardir',
            },
            'agent' => {
              'server' => 'puppet.bar.baz'
            }
          }
          facts[:augeasversion] = '1.4.0'
          facts[:openssh_version] = '5.7'
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.not_to create_pam__access__rule('allow_simp') }
          it { is_expected.not_to create_sudo__user_specification('default_simp') }
        end

        context 'with allow_simp_user => true' do
          let(:params){{
            :pam => true,
            :allow_simp_user => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::server') }
          it { is_expected.to create_pam__access__rule('allow_simp') }
          it { is_expected.to create_sudo__user_specification('default_simp') }
        end
        context 'when scenario is set to' do
          poss = [
            'pupmod',
          ]
          simp_lite = [
            'aide',
            'auditd',
            'chkrootkit',
            'at',
            'cron',
            'incron',
            'useradd',
            'resolv',
            'nsswitch',
            'issue',
            'tuned',
            'swap',
            'timezone',
            'ntpd',
            'simp::admin',
            'simp::base_apps',
            'simp::base_services',
            'simp::kmod_blacklist',
            'simp::mountpoints',
            'simp::prelink',
            'simp::sysctl',
            'ssh'
          ]
          simp = [
            'pam::wheel',
            'svckill',
          ]
          scenarios = {
            'simp' => {
              'contains' => [
                simp,
                simp_lite,
                poss,
              ],
              'does_not_contain' => [
              ]
            },
            'simp_lite' => {
              'contains' => [
                simp_lite,
                poss,
                simp
              ],
              'does_not_contain' => [
              ]
            },
            'poss' => {
              'contains' => [
                poss,
                simp_lite,
                simp,
              ],
              'does_not_contain' => [
              ]
            }
          }

          scenarios.each do |scenario, data|
            context "'#{scenario}'" do
              let(:params) {{
                :scenario => scenario
              }}

              it { is_expected.to compile.with_all_deps }
              data['contains'].flatten.each do |class_name|
                it { is_expected.to contain_class("#{class_name}") }
              end
              data['does_not_contain'].flatten.each do |class_name|
                it { is_expected.to_not contain_class("#{class_name}") }
              end
            end
          end

        end

      end
    end
  end
end
