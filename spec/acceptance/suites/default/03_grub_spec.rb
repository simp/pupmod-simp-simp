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
        let(:hieradata){
          YAML.load(File.read(File.expand_path('files/default_hiera.yaml', __dir__))).merge(
            {
              'simp::grub::password' => 'test password',
              'simp::grub::admin'    => 'admin'
            }
          )
        }

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

          password_hashes = {
            'MD5'     => '$1$ZXGfyTMV$XifqF9kIfSdTrq7Ah3m7O.',
            'SHA-256' => '$5$VugjxR6/QvxJbQ1T$94Su/6pxMIGIMDrTGPcdXG.qsUEEWSixJjiUZhY2Ww5',
            'SHA-512' => '$6$RYaPm4.l5nKMtGFf$onf.yoBtG9seECJJI2KcApOIHUBYC0..xsxa9izYDZX66nbla7SSvMMCXFlm.euizJQkzLCH0RuQN7Kami5GH/'
          }

          password_hashes.each_pair do |hash_type, pw_hash|
            context "with #{hash_type} password" do
              let(:hieradata){
                YAML.load(File.read(File.expand_path('files/default_hiera.yaml', __dir__))).merge(
                  {
                    'simp::grub::password' => pw_hash,
                    'simp::grub::admin'    => 'admin'
                  }
                )
              }

              it 'should apply manifest' do
                set_hieradata_on(host, hieradata)
                apply_manifest_on(host, manifest, :catch_failures => true)
              end

              it 'should have a the known password hash' do
                expect(password_entries.first).to match(/^password\s+--encrypted\s+#{Regexp.escape(pw_hash)}$/)
              end
            end
          end
        else
          let(:grub_cfg){ on(host, 'cat /etc/grub2.cfg').output.lines }
          let(:password_entries) {
            passwords = grub_cfg.grep(/password_pbkdf2/)

            # Remove comments
            passwords.delete_if{|x| x =~ /^\s*#/ }
            # Remove the regular 'root' entry
            passwords.delete_if{|x| x =~ / root /}

            passwords.map(&:strip)
          }

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
            expect(password_entries.count).to eq(1)
            expect(password_entries.first).to match(/^password_pbkdf2 admin grub\.pbkdf2.+/)
          end

          context 'with pregenerated password hash' do
            let(:pw_hash) {
              'grub.pbkdf2.sha512.10000.A6450DF58428B9AFDC4CED89BE2B94C74ACB153FD01BEDE4F6AEDA661854E987B1B00675533E270FFCC71FAE914789D06071704CAB9BCBB539F95C0D6952EB78.83D980313DBAE4DFE9F66EA23F91425416B4D4C816C42B6ACC0D46BBA25750203D056D5C7F103BC1A350F24F0C4AA8850961D18FD9132640723A3810BB741E4F'
            }

            let(:hieradata){
              YAML.load(File.read(File.expand_path('files/default_hiera.yaml', __dir__))).merge(
                {
                  'simp::grub::password'  => pw_hash,
                  'simp::grub::admin'     => 'admin'
                }
              )
            }

            it 'should apply manifest' do
              set_hieradata_on(host, hieradata)
              apply_manifest_on(host, manifest, :catch_failures => true)
            end

            it 'should have the known password in place' do
              expect(password_entries.count).to eq(1)
              expect(password_entries.first).to match(/^password_pbkdf2 admin #{Regexp.escape(pw_hash)}$/)
            end
          end
        end
      end
    end
  end
end
