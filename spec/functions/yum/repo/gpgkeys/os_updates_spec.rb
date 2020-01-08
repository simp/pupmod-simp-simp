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
          else
            if os_facts[:os][:name] ==  'OracleLinux'
              return_value = ['RPM-GPG-KEY-oracle']
            else
              if os_facts[:os][:name] ==  'CentOS'
                if os_facts[:os][:release][:major] <= '7'
                  return_value = ["RPM-GPG-KEY-#{os_facts[:os][:name]}-#{os_facts[:os][:release][:major]}"]
                else
                  return_value = ["RPM-GPG-KEY-#{os_facts[:os][:name]}-Official"]
                end
              else
                return_value = ["RPM-GPG-KEY-#{os_facts[:os][:name]}"]
              end
            end
          end
          it { is_expected.to run.and_return(return_value) }
        end

      end
    end
  end
end
# vim: set expandtab ts=2 sw=2:
