require 'spec_helper'

metadata_file = File.expand_path(File.join(__dir__, '..', '..', '..', '..', '..', 'metadata.json'))
metadata_json = File.read(metadata_file, {:encoding => "utf-8"} )

describe 'simp::yum::repo::internet_simp_dependencies' do

  on_supported_os.each do |os, os_facts|
    before(:each) do
      Puppet::Parser::Functions.newfunction(:load_module_metadata, :type => :rvalue) { |args| JSON.load(metadata_json) }
    end

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
          context "when `simplib::simp_version() returns an unsupported value (#{_version})" do
            let(:params) {{}}

            let(:pre_condition) do
              "function simplib::simp_version() { '#{_version}' }"
            end

            it do
              is_expected.to raise_error(/SIMP/)
            end
          end
        end

        ['6.0.0', '6.1.0-foo'].each do |_version|
          describe "when `simplib::simp_version() is valid (#{_version})" do
            let(:params) {{}}

            let(:pre_condition) do
              "function simplib::simp_version() { '#{_version}' }"
            end

            it do
              is_expected.to compile.with_all_deps
            end
          end
        end

      end
    end
  end
end
