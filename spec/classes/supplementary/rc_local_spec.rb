require 'spec_helper'

describe 'simp::rc_local' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/rc.d').with( {
            :ensure => 'directory',
            :owner  => 'root',
            :group  => 'root',
            :mode   => '0644'
          } )
        end

        it do
          is_expected.to contain_file('/etc/rc.local').with( {
            :ensure => 'link',
            :target => '/etc/rc.d/rc.local'
          } )
        end

        it do
          expected = <<EOM
#!/bin/bash
#
# This file managed by Puppet, manual changes will be erased!
# This file Disabled via Puppet
EOM
          is_expected.to contain_file('/etc/rc.d/rc.local').with( {
            :ensure  => 'file',
            :owner   => 'root',
            :group   => 'root',
            :mode    => '0755',
            :content => expected.strip
          } )
        end

      end

      context 'with custom content' do
        let(:params) {{ :content => '# My comment' }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected = <<EOM
#!/bin/bash
#
# This file managed by Puppet, manual changes will be erased!
# My comment
EOM
          is_expected.to contain_file('/etc/rc.d/rc.local').with_content(
            expected.strip)
        end
      end

      context 'with management_comment = false' do
        let(:params) {{ :management_comment => false }}

        it { is_expected.to compile.with_all_deps }
        it do
          expected = <<EOM
#!/bin/bash
# This file Disabled via Puppet
EOM
          is_expected.to contain_file('/etc/rc.d/rc.local').with_content(
            expected.strip)
        end
      end
    end
  end
end
