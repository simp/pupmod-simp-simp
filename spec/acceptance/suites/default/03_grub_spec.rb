require 'spec_helper_acceptance'
require 'json'

test_name 'simp::grub'

describe 'simp::grub class' do
  let(:manifest) {
    <<-EOS
      include 'simp::grub'
    EOS
  }

  hosts.each do |host|
    context "on #{host}" do

      grub_version = 1

      if on(host, 'ls /etc/grub2.cfg', :accept_all_exit_codes => true).exit_code == 0
        grub_version = 2
      end

      context "with GRUB #{grub_version}" do
        let(:hieradata){{
          'simp::grub::password' => 'test password',
          'simp::grub::admin'    => 'admin'
        }}

        it 'should apply manifest' do
          set_hieradata_on(host, hieradata)
          apply_manifest_on(host, manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(host, manifest, :catch_changes => true)
        end

        if grub_version == 1
          let(:password_entries){ on(host, 'grep password /etc/grub.conf').output.lines }

          it 'should only have one password entry' do
            expect(password_entries.count).to eq(1)
          end

          it 'should have a SHA-512 encrypted password entry' do
            expect(password_entries.first).to match(/^password\s+--encrypted\s+\$6\$/)
          end
        else
          let(:grub_cfg){ on(host, 'cat /etc/grub2.cfg').output.lines }

          it 'should have a superuser named "admin"' do
            superusers = grub_cfg.grep(/set\s+superusers/)

            # Remove comments
            superusers.delete_if{|x| x =~ /^\s*#/ }
            # Remove the regular 'root' entry
            superusers.delete_if{|x| x =~ /"root"/}

            superusers.map!(&:strip)

            expect(superusers).to eq(['set superusers="admin"'])
          end

          it 'should have a password in place for "admin"' do
            passwords = grub_cfg.grep(/password_pbkdf2/)

            # Remove comments
            passwords.delete_if{|x| x =~ /^\s*#/ }
            # Remove the regular 'root' entry
            passwords.delete_if{|x| x =~ / root /}

            passwords.map!(&:strip)

            expect(passwords.count).to eq(1)
            expect(passwords.first).to match(/^password_pbkdf2 admin grub\.pbkdf2.+/)
          end
        end
      end
    end
  end
end
