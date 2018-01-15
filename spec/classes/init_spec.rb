require 'spec_helper'
require 'facterdb'

describe 'simp' do

  # Unsupported OSes systems should only be able to use scenarios 'poss' and 'none'
  context 'on unsupported operating systems' do
    facterdb_queries = [
      {:operatingsystem => 'OracleLinux',:operatingsystemmajrelease => '7'},
      {:operatingsystem => 'Ubuntu',:operatingsystemmajrelease => '16.04'},
    ].map{|q| q.merge({:hardwaremodel => 'x86_64', :facterversion => '3.5.1'})}

    facterdb_queries.each do |facterdb_query|

      os_facts = FacterDB.get_facts(facterdb_query).first
      os     = "#{os_facts[:os]['name'].downcase}-" +
               "#{os_facts[:os]['release']['major']}-" +
               "#{os_facts[:os]['hardware']}"

      context "on #{os}" do
        let(:facts) do
            os_facts[:puppet_vardir] = '/opt/puppetlabs/puppet/cache'
            os_facts[:puppet_settings] = {
              'ssldir' => '/opt/puppetlabs/puppet/vardir',
              'agent' => {
                'server' => 'puppet.bar.baz'
              }
            }
            os_facts[:server_facts] = {
              :servername => 'puppet.bar.baz',
              :serverip   => '1.2.3.4'
            }
            os_facts
        end

        context 'with default parameters (scenario defaults to simp)' do
          it do
            skip 'FIXME:' +  <<-EOM

              This is the most reasonable error to expect, but it won't happen:

              On unsupported RedHat OSes like OracleLinux, the hierarchy in hiera.yaml uses
              `facts.osfamily` + 'os/RedHat.yaml' as an (overly-broad) shortcut for keeping
              scenario_map defs DRY for the RedHat and CentOS operating systems.

              On unsupported & non-RedHat OSes, compilation will fail with `Evaluation Error:
              Error while evaluating a Function Call, Class[Simp]: expects a value for
              parameter 'scenario_map'  at line 2:1`
            EOM
            is_expected.to compile.and_raise_error(/Invalid scenario 'simp' for the given scenario map/)
          end
        end

        context 'with scenario "poss"' do
          let :params do
            { :scenario => 'poss' }
          end

          it do
            unless facts[:osfamily] == 'RedHat'
              skip 'FIXME:' +  <<-EOM

                This should work on unsupported, non-redhat-osfamily oses.

                instead, compilation will fail with `evaluation error: error while evaluating a
                resource statement, class[simp]: expects a value for parameter 'scenario_map'
                at line 2:1`
              EOM
            end
            is_expected.to compile.with_all_deps
          end

          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to create_class('simp') }
          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to create_class('pupmod') }
          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to create_class('pupmod::agent::cron') }
          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to_not create_class('sudosh') }
          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to_not create_class('ssh') }
        end

        context 'with scenario "none"' do
          let :params do
            { :scenario => 'none' }
          end

          it do
            unless facts[:osfamily] == 'RedHat'
              skip 'FIXME:' +  <<-EOM

                This should work on unsupported, non-redhat-osfamily oses.

                instead, compilation will fail with `evaluation error: error while evaluating a
                resource statement, class[simp]: expects a value for parameter 'scenario_map'
                at line 2:1`
              EOM
            end
            is_expected.to compile.with_all_deps
          end

          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to create_class('simp') }
          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to_not create_class('pupmod') }
          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to_not create_class('pupmod::agent::cron') }
          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to_not create_class('sudosh') }
          it {
            skip 'FIXME: same as above' unless (facts[:osfamily] == 'RedHat')
            is_expected.to_not create_class('ssh') }
        end
      end
    end
  end


  context 'on supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:openssh_version] = '5.8'
          facts[:augeasversion] = '1.2.3'
          facts[:puppet_vardir] = '/opt/puppetlabs/puppet/cache'
          facts[:puppet_settings] = {
            'ssldir' => '/opt/puppetlabs/puppet/vardir',
            'agent' => {
              'server' => 'puppet.bar.baz'
            }
          }
          facts[:server_facts] = {
            :servername => 'puppet.bar.baz',
            :serverip   => '1.2.3.4'
          }
          facts
        end
        let(:hieradata) { "sssd::domains: ['LDAP']" }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/opt/puppetlabs/puppet/cache/simp') }
        it { is_expected.to create_host('puppet.bar.baz').with_ip('1.2.3.4') }
        it { is_expected.to create_stunnel__connection('rsync') }
        it { is_expected.to_not create_filebucket('simp') }

        # For use with the next test
        it { is_expected.to create_class('aide') }
        context 'when removing classes using a knockout in simp::classes' do
          {
            "when classes are just added" => {
              :params => {
                "classes" => [ 'simp::yum::schedule' ]
              },
              :contains => [ 'simp::yum::schedule'],
              :not_contains => [ ],
            }
          }.each do |ctxt, hash |
            context ctxt do
              let (:params) do
                hash[:params]
              end
              it { is_expected.to compile.with_all_deps }
              hash[:contains].each do |klass|
                it { is_expected.to create_class(klass) }
              end
            end
          end
        end

        context 'with filebucketing' do
          context 'with local path' do
            let(:params) {{ :enable_filebucketing => true }}

            it { is_expected.to create_file('/etc/rc.d/rc.local').with_backup('simp') }
            it { is_expected.to create_filebucket('simp').with_path("#{facts[:puppet_vardir]}/simp/filebucket") }
          end

          context 'with remote server' do
            let(:params) {{
              :enable_filebucketing => true,
              :filebucket_server    => 'my.puppet.server'
            }}

            it { is_expected.to create_file('/etc/rc.d/rc.local').with_backup('simp') }
            it { is_expected.to create_filebucket('simp').with_server(params[:filebucket_server]) }
          end
        end

        context 'rsync_stunnel logic' do
          context 'with rsync_stunnel => false' do
            let(:params) {{ :rsync_stunnel => false }}
            it { is_expected.not_to create_stunnel__connection('rsync') }
          end
          context 'with rsync_stunnel => Simplib::Host' do
            let(:params) {{ :rsync_stunnel => 'other.test.host' }}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['other.test.host:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
          context 'with rsync_stunnel => true' do
            let(:params) {{ :rsync_stunnel => true }}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['1.2.3.4:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
          context 'without $server_facts' do
            let(:facts) {facts.merge({ :server_facts => nil })}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['puppet.bar.baz:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
        end

        context 'when scenario is set to' do
          poss = [
            'pupmod',
          ]
          simp_lite = [
            'simp::scenario::base',
            'aide',
            'auditd',
            'clamav',
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
            'simp_rsyslog',
            'simp::admin',
            'simp::base_apps',
            'simp::base_services',
            'simp::yum::schedule',
            'simp::kmod_blacklist',
            'simp::mountpoints',
            'simp::prelink',
            'simp::sysctl',
            'ssh',
            'sudosh',
          ]
          simp = [
            'pam::wheel',
            'selinux',
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
              ],
              'does_not_contain' => [
                simp
              ]
            },
            'poss' => {
              'contains' => [
                poss,
              ],
              'does_not_contain' => [
                simp_lite,
                simp,
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
