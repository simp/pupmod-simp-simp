require 'spec_helper_acceptance'

test_name 'simp_admin'

describe 'simp_admin' do
  let(:manifest) do
    <<-EOS
      include 'simp::admin'
    EOS
  end

  hosts.each do |host|
    context "on #{host}" do
      context 'logging shell' do
        context 'using tlog (default)' do
          it 'runs puppet' do
            apply_manifest_on(host, manifest, catch_changes: false)
          end

          it 'is idempotent' do
            apply_manifest_on(host, manifest, catch_changes: true)
          end

          it 'has tlog installed' do
            expect(host.check_for_package('tlog')).to be true
          end
        end

      end
    end
  end
end
