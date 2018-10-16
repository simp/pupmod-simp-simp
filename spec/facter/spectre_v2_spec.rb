require 'spec_helper'

describe 'spectre_v2' do
  before do
    Facter.fact(:kernel).stubs(:value).returns(:linux)
  end
  after do
    Facter.clear
  end

  context "The system has  spectre patch" do
    it 'should return true' do
      File.stubs(:exists?).with("/sys/kernel/debug/x86/ibrs_enabled").returns true
      expect(Facter.fact(:spectre_v2).value).to eq(true)
    end
  end

  context "The system is not  spectre patched" do
    it 'should return true' do
      File.stubs(:exists?).with("/sys/kernel/debug/x86/ibrs_enabled").returns false
      expect(Facter.fact(:spectre_v2).value).to eq(false)
    end
  end
end
