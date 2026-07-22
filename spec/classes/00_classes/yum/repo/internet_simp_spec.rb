require 'spec_helper'

describe 'simp::yum::repo::internet_simp' do
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

        context 'with default parameters and a released version auto-detected' do
          let(:pre_condition) { "function simplib::simp_version() { '6.5.0-0' }" }

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_package('simp-release-community').with_source(
            'https://download.simp-project.com/simp-release-community.rpm',
          )
          }

          it {
            is_expected.to contain_file('/etc/yum/vars/simprelease').with(
            owner: 'root',
            group: 'root',
            mode: '0644',
            content: "6.5.0-0\n",
          )
          }

          it {
            is_expected.to contain_file('/etc/yum/vars/simpreleasetype').with(
            owner: 'root',
            group: 'root',
            mode: '0644',
            content: "releases\n",
          )
          }
        end

        context 'with default parameters and a testing version auto-detected' do
          let(:pre_condition) { "function simplib::simp_version() { '6.5.0-Alpha' }" }

          it { is_expected.to raise_error(%r{SIMP version}) }
        end

        context 'with simp_release_version specified' do
          let(:params) { { simp_release_version: '6' } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_package('simp-release-community') }
          it { is_expected.to contain_file('/etc/yum/vars/simprelease').with_content("6\n") }
          it { is_expected.to contain_file('/etc/yum/vars/simpreleasetype').with_content("releases\n") }
        end

      end
    end
  end
end
