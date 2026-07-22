require 'spec_helper'

describe 'simp::yum::repo::gpgkeys::os_updates' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        let(:return_value) do
          if os_facts[:os][:name] == 'RedHat'
            ['RPM-GPG-KEY-redhat-release']
          elsif os_facts[:os][:name] ==  'OracleLinux'
            ['RPM-GPG-KEY-oracle']
          elsif os_facts[:os][:name] ==  'CentOS'
            ["RPM-GPG-KEY-#{os_facts[:os][:name]}-#{os_facts[:os][:release][:major]}"]
          elsif os_facts[:os][:name] ==  'Rocky'
            ['RPM-GPG-KEY-rockyofficial']
          else
            ["RPM-GPG-KEY-#{os_facts[:os][:name]}"]
          end
        end

        it { is_expected.to run.and_return(return_value) }
      end
    end
  end
end
# vim: set expandtab ts=2 sw=2:
