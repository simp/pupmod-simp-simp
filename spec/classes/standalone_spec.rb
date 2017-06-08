require 'spec_helper'

describe 'simp::standalone' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        let(:username) { 'simp_standalone' }

        shared_examples_for "a standalone system" do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp::standalone') }
          it { is_expected.to create_class('simp::standalone::user') }
          it { is_expected.to create_class('simp::standalone::finalize').with_stage("#{username}_finalization") }
          it { is_expected.to create_stage("#{username}_finalization").that_requires('Stage[simp_finalize]') }
          it { is_expected.to create_file('/usr/local/sbin/simp_standalone_finalize.sh') }
          it { is_expected.to create_exec('standalone finalize').that_requires('File[/usr/local/sbin/simp_standalone_finalize.sh]') }
        end

        shared_examples_for 'a standalone system user' do
          it { is_expected.to create_user(username) }
          it { is_expected.to create_group(username) }
          it { is_expected.to create_file("/var/local/#{username}") }
          it {
            is_expected.to create_pam__access__rule("allow_#{username}").with_origins(['LOCAL', 'ALL'])
          }
          it { is_expected.to create_sudo__user_specification(username) }
        end

        context 'with no params' do
          it { expect{ is_expected.to compile.with_all_deps }.to raise_error(/must specify either.+user_password.+user_ssh_authorized_key/) }
        end

        context 'with user_password defined' do
          let(:params) {{
            :user_password => '$2$blahthing'
          }}

          it_behaves_like 'a standalone system'
          it_behaves_like 'a standalone system user'
        end

        context 'with user SSH key defined' do
          let(:params) {{
            :user_ssh_authorized_key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDGUpa76k+ehDp1VHtm844RZsVQtMDKk8Md4bM1fGM2Ro7OX3GEUhKcabioaAZq7W6mO+0O679w22b8J7rf7sBTKVxuh1AWWsTln2oKKGHqFDErAyXw0jT5imdycGaemoQeBDanjfbY2OlmzAZQqYDeMV1iJ+06b05WrnR3hsUZ+jVBBBd6t5+a5pwm1Ng2DRCsO47nzMr1SDm3+TwJ2PPMUyMotaJzE3zMCDtf3OvLJb2+zxApastaXZ0Gkboqxy4TEcZqgTcf1Ac05k45By/2NZ0CiYsW7SCN6/8jR2G8CB5f2qD0GAxzuXmsue/2Yrt63BXyCbThxzwocu1Ebmsp'
          }}

          it_behaves_like 'a standalone system'
          it_behaves_like 'a standalone system user'

          it { is_expected.to create_ssh_authorized_key(username).with_key(params[:user_ssh_authorized_key]) }
        end

        context 'when user management disabled' do
          let(:params) {{ :enable_user => false }}

          it_behaves_like 'a standalone system'

          it { is_expected.to create_user(username).with_ensure('absent') }
          it { is_expected.to create_group(username).with_ensure('absent') }
          it { is_expected.to_not create_file("/var/local/#{username}") }
          it { is_expected.to_not create_pam__access__rule("allow_#{username}") }
          it { is_expected.to_not create_sudo__user_specification(username) }
        end
      end
    end
  end
end
