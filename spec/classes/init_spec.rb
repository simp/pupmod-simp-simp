require 'spec_helper'

describe 'simp' do
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
          facts['puppet_vardir'] = '/opt/puppetlabs/puppet/cache'
          facts[:ipaddress_eth0] = '10.0.2.15'

          facts
        end

        let(:precondition) {
          %(hiera_include('classes'))
        }

        context 'default' do
          # it { require 'pry';binding.pry }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/opt/puppetlabs/puppet/cache/simp') }
        end

        context 'with_puppet_server' do
          let(:params) {{ :puppet_server_ip => '1.2.3.4' }}

          it { is_expected.to create_host('puppet.bar.baz').with_ip('1.2.3.4') }
        end


        context 'rsync_stunnel logic' do
          context 'with rsync_stunnel defined' do
            let(:params) {{ :rsync_stunnel => 'puppet.bar.baz' }}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['puppet.bar.baz:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
          context 'with rsync_stunnel undefined but servername defined' do
            let(:facts) { facts.merge({ :servername => 'puppet.server.name' })}
            let(:params) {{ :rsync_stunnel => '' }}
            it { is_expected.to create_stunnel__connection('rsync').with({
              :connect => ['puppet.server.name:8730'],
              :accept  => '127.0.0.1:873'
            }) }
          end
          context 'with neither defined' do
            let(:facts) { facts.merge({ :servername => '' })}
            let(:params) {{ :rsync_stunnel => '' }}
            it { is_expected.not_to create_stunnel__connection('rsync') }
          end
        end

      end
    end
  end
end
