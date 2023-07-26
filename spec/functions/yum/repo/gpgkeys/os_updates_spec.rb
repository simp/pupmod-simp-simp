require 'spec_helper'

# vim: set expandtab ts=2 sw=2:
describe 'simp::yum::repo::gpgkeys::os_updates' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do

        if os_facts[:kernel] != 'windows'
          let(:facts){ os_facts }

          if os_facts[:os][:name] == 'RedHat'
            return_value = ['RPM-GPG-KEY-redhat-release']
          elsif os_facts[:os][:name] ==  'OracleLinux'
            return_value = ['RPM-GPG-KEY-oracle']
          elsif os_facts[:os][:name] ==  'CentOS'
            return_value = ["RPM-GPG-KEY-#{os_facts[:os][:name]}-#{os_facts[:os][:release][:major]}"]
          elsif os_facts[:os][:name] ==  'Rocky'
            return_value = ['RPM-GPG-KEY-rockyofficial']
          else
            return_value = ["RPM-GPG-KEY-#{os_facts[:os][:name]}"]
          end

      end
    end
  end
end
# vim: set expandtab ts=2 sw=2:
