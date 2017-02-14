require 'spec_helper'

describe 'simp::yum' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        # it { require 'pry';binding.pry }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_yumrepo('simp').with({
            :gpgkey  => %r(^https://yum.bar.baz/yum/SIMP),
            :baseurl => %r(^https://yum.bar.baz/yum/SIMP)
        }) }

        if facts[:os][:release][:major].to_s == '6' and facts[:os][:name] == 'CentOS'
          it { is_expected.to create_yumrepo('os_updates').with({
              :gpgkey  => %r(^https://yum.bar.baz/yum/CentOS/6/x86_64/RPM-GPG-KEY-CentOS-6),
              :baseurl => %r(^https://yum.bar.baz/yum/CentOS/6/x86_64/Updates)
          }) }
        end
      end
    end
  end
end
