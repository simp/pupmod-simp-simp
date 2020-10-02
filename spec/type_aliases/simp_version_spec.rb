require 'spec_helper'

describe 'Simp::Version' do
  context 'with valid versions ' do
    it { is_expected.to allow_value('6') }
    it { is_expected.to allow_value('6.5') }
    it { is_expected.to allow_value('6.5.0') }
    it { is_expected.to allow_value('6.5.0-0') }
  end

  context 'with invalid versions' do
    it { is_expected.not_to allow_value('6.*') }
    it { is_expected.not_to allow_value('6.5.*') }
    it { is_expected.not_to allow_value('6.5.0-Alpha') }
    it { is_expected.not_to allow_value('6.5.0.0-1') }
    it { is_expected.not_to allow_value('6_X') }
    it { is_expected.not_to allow_value('6_X_Dependencies') }
  end
end
