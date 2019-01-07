require 'spec_helper'

describe 'simp::root_user' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts){ os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('simp::root_user') }

      context 'manages root user by default' do
        it { is_expected.to create_file('/root') }
        it { is_expected.to create_user('root').without_password }
        it { is_expected.to create_group('root') }
      end

      context 'unless told not to' do
        let(:params) {{
          :manage_perms => false,
          :manage_user  => false,
          :manage_group => false
        }}
        it { is_expected.not_to create_file('/root') }
        it { is_expected.not_to create_user('root') }
        it { is_expected.not_to create_group('root') }
      end

      context 'with clear-text password and hash_password => true' do
        let(:params) {{
          :password => 'mysecretpassword'
        }}
        it { is_expected.to create_file('/root') }
        it { is_expected.to create_user('root').with_password(/\$6\$/) }
        it { is_expected.to create_group('root') }
      end

      context 'with sha512 password and hash_password => false' do
        let(:params) {{
          :password => '$6$fdkjfdk$yj8HAo/RyW/WhYkXvTp7nQbjIZz4TMRuj/0W1bJGuQjGxea36JhUkB36BMyf8O/g0/rpRB1lPC/6KuAmgqnIn0'
        }}
        it { is_expected.to create_file('/root') }
        it { is_expected.to create_user('root').with_password('$6$fdkjfdk$yj8HAo/RyW/WhYkXvTp7nQbjIZz4TMRuj/0W1bJGuQjGxea36JhUkB36BMyf8O/g0/rpRB1lPC/6KuAmgqnIn0') }
        it { is_expected.to create_group('root') }
      end
    end
  end
end
