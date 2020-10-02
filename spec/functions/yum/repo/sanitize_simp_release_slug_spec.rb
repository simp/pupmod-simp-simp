require 'spec_helper'

describe 'simp::yum::repo::sanitize_simp_release_slug' do
  context 'when version can be determined' do
    let(:pre_condition) { "function simplib::simp_version() { '6.5.0-0' }" }
    
    it { is_expected.to run.with_params('6_X').and_return('6_X') }
    it { is_expected.to run.with_params('').and_return('6_X') }
    it { is_expected.to run.with_params().and_return('6_X') }
  end

  context 'when version cannot be determined' do
    let(:pre_condition) { "function simplib::simp_version() { 'unknown' }" }
    let(:err_msg) { 'SIMP version unknown does not map to a known yum repository slug' }

    it { is_expected.to run.with_params().and_raise_error(/#{err_msg}/) }
  end
end
