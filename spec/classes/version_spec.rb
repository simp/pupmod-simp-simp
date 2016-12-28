require 'spec_helper'

describe 'simp::version' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts){ os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('simp::version') }

      it { is_expected.to create_file('/etc/simp') }
      it { is_expected.to create_file('/etc/simp/simp.version') }
      it { is_expected.to create_file('/usr/local/sbin/simp') }

    end
  end
end
