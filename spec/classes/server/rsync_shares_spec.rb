require 'spec_helper'

describe 'simp::server::rsync_shares' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:simp_rsync_environments] = {
            environment => {
              'rsync' => {
                'global' => {
                  'id' => 'Global',
                  'shares' => [
                    'clamav',
                    'mcafee',
                    'jenkins_plugins'
                  ]
                },
                'redhat' => {
                  'id' => 'RedHat',
                  '6' => {
                    'id' => '6',
                    'shares' => [
                      'bind_dns'
                    ]
                  },
                  '7' => {
                    'id' => '7',
                    'shares' => [
                      'bind_dns'
                    ]
                  },
                  'global' => {
                    'id' => 'Global',
                    'shares' => [
                      'apache',
                      'dhcpd',
                      'freeradius',
                      'snmp',
                      'tftpboot'
                    ]
                  }
                }
              }
            }
          }

          facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::server::rsync_shares') }
        it { is_expected.to create_rsync__server__section("clamav_#{environment}") }
        it { is_expected.to create_rsync__server__section("mcafee_#{environment}") }
        it { is_expected.to create_rsync__server__section("jenkins_plugins_#{environment}") }
        it { is_expected.to create_rsync__server__section("bind_dns_default_#{environment}_redhat_6") }
        it { is_expected.to create_rsync__server__section("bind_dns_default_#{environment}_redhat_7") }
        it { is_expected.to create_rsync__server__section("apache_#{environment}_redhat") }
        it { is_expected.to create_rsync__server__section("tftpboot_#{environment}_redhat") }
        it { is_expected.to create_rsync__server__section("dhcpd_#{environment}_redhat") }
        it { is_expected.to create_rsync__server__section("snmp_#{environment}_redhat") }
        it { is_expected.to create_rsync__server__section("freeradius_#{environment}_redhat") }

        context 'with a limited share set' do
          let(:facts) do
            facts[:simp_rsync_environments] = {
              environment => {
                'rsync' => {
                  'global' => {
                    'id' => 'Global',
                    'shares' => [ 'clamav' ]
                  },
                  'redhat' => {
                    'id' => 'RedHat',
                    '7' => {
                      'id' => '7',
                      'shares' => [
                        'bind_dns'
                      ]
                    },
                    'global' => {
                      'id' => 'Global',
                      'shares' => [
                        'apache',
                        'tftpboot'
                      ]
                    }
                  }
                }
              }
            }

            facts
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::server::rsync_shares') }
          it { is_expected.to create_rsync__server__section("clamav_#{environment}") }
          it { is_expected.to_not create_rsync__server__section("mcafee_#{environment}") }
          it { is_expected.to_not create_rsync__server__section("jenkins_plugins_#{environment}") }
          it { is_expected.to_not create_rsync__server__section("bind_dns_default_#{environment}_redhat_6") }
          it { is_expected.to create_rsync__server__section("bind_dns_default_#{environment}_redhat_7") }
          it { is_expected.to create_rsync__server__section("apache_#{environment}_redhat") }
          it { is_expected.to create_rsync__server__section("tftpboot_#{environment}_redhat") }
          it { is_expected.to_not create_rsync__server__section("dhcpd_#{environment}_redhat") }
          it { is_expected.to_not create_rsync__server__section("snmp_#{environment}_redhat") }
          it { is_expected.to_not create_rsync__server__section("freeradius_#{environment}_redhat") }
        end
      end
    end
  end
end
