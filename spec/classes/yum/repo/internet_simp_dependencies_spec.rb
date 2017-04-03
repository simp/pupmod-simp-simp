require 'spec_helper'

describe 'simp::yum::repo::internet_simp_dependencies' do

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

      let(:facts) do
        os_facts
      end

      context 'when the `simp_release_slug` parameter is specified' do
        let(:params) {{ :simp_release_slug => '5_X' }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_yumrepo('simp-project_5_X_Dependencies') }
      end

      context 'when `simp_release_slug` is undef' do
        ['4.0.0', ''].each do |_version|
          context "when `simp_version() returns an unsupported value (#{_version})" do
            let(:params) {{}}

            before(:each) do
              Puppet::Parser::Functions.newfunction(:simp_version, :type => :rvalue) { |args|
                _version
              }
            end
            it { is_expected.to raise_error(/SIMP/)}
          end
        end

        ['6.0.0', '6.1.0-foo'].each do |_version|
          describe "when `simp_version() is valid (#{_version})" do
            let(:params) {{}}
            before(:each) do
              Puppet::Parser::Functions.newfunction(:simp_version, :type => :rvalue) { |args|
                _version
              }
            end
            it { is_expected.to compile.with_all_deps }
          end
        end

      end
    end
  end
end
