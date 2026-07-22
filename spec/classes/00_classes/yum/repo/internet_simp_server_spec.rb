require 'spec_helper'

describe 'simp::yum::repo::internet_simp_server' do
  let(:metadata_json) do
    metadata_file = File.expand_path(File.join(__dir__, '..', '..', '..', '..', '..', 'metadata.json'))
    File.read(metadata_file, encoding: 'utf-8')
  end

  on_supported_os.each do |os, os_facts|
    before(:each) do
      metadata = metadata_json
      Puppet::Parser::Functions.newfunction(:load_module_metadata, type: :rvalue) { |_args| JSON.parse(metadata) }
    end

    context "on #{os}" do
      let(:facts) { os_facts }

      if os_facts[:kernel] == 'windows'
        it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{'windows .+' is not supported}) }
      else
        context 'when the `simp_release_slug` parameter is specified' do
          let(:params) { { simp_release_slug: '5_X' } }

          let(:pre_condition) do
            "function simplib::simp_version() { '5.3.0' }"
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_yumrepo('simp-project_5_X').with_ensure('absent') }
          it { is_expected.to create_class('simp::yum::repo::internet_simp') }
        end

        context 'when `simp_release_slug` is undef' do
          ['4.0.0', 'unknown', ''].each do |version|
            context "when `simplib::simp_version() returns an unsupported value (#{version})" do
              let(:params) { {} }

              let(:pre_condition) do
                "function simplib::simp_version() { '#{version}' }"
              end

              it do
                is_expected.to raise_error(%r{SIMP})
              end
            end
          end

          ['6.0.0', '6.1.0-0'].each do |version|
            describe "when `simplib::simp_version() is valid (#{version})" do
              let(:params) { {} }

              let(:pre_condition) do
                "function simplib::simp_version() { '#{version}' }"
              end

              it { is_expected.to compile.with_all_deps }
              it { is_expected.to contain_yumrepo('simp-project_6_X').with_ensure('absent') }
              it { is_expected.to create_class('simp::yum::repo::internet_simp') }
            end
          end
        end
      end
    end
  end
end
