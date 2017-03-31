require 'spec_helper'

shared_examples 'simp::knockout()' do |input_array, return_value|
  it { is_expected.to run.with_params(input_array).and_return(return_value) }
end

describe 'simp::knockout' do
  context 'when a simple array is passed' do
    it_behaves_like 'simp::knockout()',
                    %w(socrates plato aristotle),
                    %w(socrates plato aristotle)
  end

  context 'when passed a mixed array' do
    it_behaves_like 'simp::knockout()',
                    %w(socrates plato aristotle --socrates),
                    %w(plato aristotle)
  end

  context 'when passed a mixed array where everything is knocked out' do
    it_behaves_like 'simp::knockout()',
                    %w(socrates plato aristotle --plato --aristotle --socrates),
                    []
  end
end
# vim: set expandtab ts=2 sw=2:
