require 'spec_helper'

el7_absent_packages =  [
          'tftp-server',
          'rsh-server',
          'ypserv',
          'telnet-server',
          'vsftpd'
]

describe 'simp::stig_packages::ensure_absent' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        if os_facts[:os][:release][:major].to_i >= 7
          el7_absent_packages.each do |package|
            it { is_expected.to create_package(package).with_ensure('absent') }
          end
        end
      end

    end
  end
end
