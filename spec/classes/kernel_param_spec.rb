require 'spec_helper'

describe 'simp::kernel_param' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
        facts.merge({ :spectre_v2 => true,
                      :meltdown   => true
        })
      end

      context "with default parameters" do
        it {
          is_expected.to create_kernel_parameter('kpti').with(:ensure => 'absent')
          is_expected.to create_kernel_parameter('nopti').with(:ensure => 'absent')
          is_expected.to create_kernel_parameter('spectre_v2').with(:ensure => 'absent')
          is_expected.to create_kernel_parameter('nospectre_v2').with(:ensure => 'absent')
        }
      end

      context "with params set" do
        let(:params) {{
          :pti => false,
          :spectre_v2 => 'off'
        }}

        it {
          is_expected.to create_kernel_parameter('kpti').with(:ensure => 'absent')
          is_expected.to create_kernel_parameter('nopti').with(:ensure => 'present')
          is_expected.to create_kernel_parameter('spectre_v2').with(:value => 'off')
          is_expected.to create_kernel_parameter('nospectre_v2').with(:ensure => 'absent')
        }
      end

      context "with system not spectre_patched" do
        let(:facts) do
          facts
          facts.merge({ :spectre_v2 => false,
                        :meltdown   => false
          })
        end
        it {
          is_expected.not_to create_kernel_parameter('kpti')
          is_expected.not_to create_kernel_parameter('nopti')
          is_expected.not_to create_kernel_parameter('spectre_v2')
          is_expected.not_to create_kernel_parameter('nospectre_v2')
        }
      end
    end
  end
end
