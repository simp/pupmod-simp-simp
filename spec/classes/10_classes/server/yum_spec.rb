require 'spec_helper'

describe 'simp::server::yum' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      if os_facts[:kernel] == 'windows'
        it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
      else
        context 'default parameters' do
          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_simp_apache__site('yum').with_content(<<-EOM,
Alias /yum /var/www/yum

<Location /yum>
    Options +Indexes

    Order allow,deny
    Allow from 127.0.0.1
    Allow from ::1
    Allow from 1.2.3.0/24
    Allow from 5.6.0.0/16
    Allow from example.com
</Location>

          EOM
                                                                        )
          }
          it { is_expected.to contain_package('createrepo') }
        end

        context 'trusted_nets = [ 0.0.0.0/0 ]' do
          # Apache needs 0.0.0.0/0 to be translated to ALL
          let(:params) { { trusted_nets: [ '0.0.0.0/0' ] } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_simp_apache__site('yum').with_content(%r{Allow from ALL}) }
        end

        context 'trusted_nets = ALL' do
          let(:params) { { trusted_nets: [ 'ALL' ] } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_simp_apache__site('yum').with_content(%r{Allow from ALL}) }
        end
      end
    end
  end
end
