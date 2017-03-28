require 'spec_helper'

describe 'simp::knockout' do
  {
    "when a simple array is passed" => {
      :array => ['socrates', 'plato', 'aristotle'],
      :return => ['socrates', 'plato', 'aristotle'],
    },
    "when passed a mixed array" => {
      :array => ['socrates', 'plato', 'aristotle', '--socrates'],
      :return => ['plato', 'aristotle'],
    },
    "when passed a mixed array where everything is knocked out" => {
      :array => ['socrates', 'plato', 'aristotle', '--plato', '--aristotle', '--socrates'],
      :return => [],
    },
  }.each do |context, test_spec|
    context context do
      let(:array) { test_spec[:array] }
      it { is_expected.to run.with_params(array).and_return(test_spec[:return]) }
    end
  end
end

# vim: set expandtab ts=2 sw=2:
