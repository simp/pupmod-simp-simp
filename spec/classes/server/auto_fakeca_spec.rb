# Can't run this until lwe get access to server_facts
require 'spec_helper'

describe 'simp::server::auto_fakeca' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:puppet_settings] = {
            :ca => {
              :signeddir => '/var/ca/stuff'
            }
          }

          facts
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to create_incron__system_table('hook_fakeca_to_puppet').with({
            'path'    => facts[:puppet_settings][:ca][:signeddir],
            'mask'    => ['IN_CREATE', 'IN_DELETE'],
            'command' => '/usr/local/sbin/simp_fakeca_incron_hook $% $#'
          })
        }

        context 'without file deletion' do
          let(:params){{
            'delete_on_removal' => false
          }}

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to create_incron__system_table('hook_fakeca_to_puppet').with({
              'path'    => facts[:puppet_settings][:ca][:signeddir],
              'mask'    => ['IN_CREATE'],
              'command' => '/usr/local/sbin/simp_fakeca_incron_hook $% $#'
            })
          }
        end
      end
    end
  end
end
