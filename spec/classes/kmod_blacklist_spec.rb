require 'spec_helper'

describe 'simp::kmod_blacklist' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts['augeasversion'] = '1.4.0'
          facts
        end

        let(:stock_blacklist) {
          ['bluetooth', 'cramfs', 'dccp', 'dccp_ipv4',
           'dccp_ipv6', 'freevxfs', 'hfs', 'hfsplus',
           'ieee1394', 'jffs2', 'net-pf-31', 'rds', 'sctp',
           'squashfs', 'tipc', 'udf', 'usb-storage']
        }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp::kmod_blacklist') }

        context 'with default parameters' do
          it 'should blacklist all the default kmods' do
            stock_blacklist.each do |mod|
              is_expected.to create_kmod__blacklist(mod)
            end
          end
        end

        context 'with custom kmods' do
          let(:custom_list) { ['nfs','fuse'] }
          let(:params) {{ :custom_blacklist => custom_list }}
          it 'should include all the kmods in the blacklist' do
            (stock_blacklist + custom_list).each do |mod|
              is_expected.to create_kmod__blacklist(mod)
            end
          end
        end

        context 'with the default list disabled' do
          let(:custom_list) { ['nfs','fuse'] }
          let(:params) {{
            :enable_defaults  => false,
            :custom_blacklist => custom_list
          }}
          it 'should include only the custom the kmods in the blacklist' do
            custom_list.each do |mod|
              is_expected.to create_kmod__blacklist(mod)
            end
          end
        end

      end
    end
  end
end
