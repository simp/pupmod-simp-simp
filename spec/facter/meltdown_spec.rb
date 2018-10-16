require 'spec_helper'

describe 'meltdown' do
  before do
    Facter.fact(:kernel).stubs(:value).returns(:linux)
  end
  after do
    Facter.clear
  end

  context "The system has meltdown patch" do
    it 'should return true' do
      File.stubs(:exists?).with("/sys/kernel/debug/x86/pti_enabled").returns true
      expect(Facter.fact(:meltdown).value).to eq(true)
    end
  end

  context "The system is not  meltdown patched" do
    it 'should return true' do
      File.stubs(:exists?).with("/sys/kernel/debug/x86/pti_enabled").returns false
      expect(Facter.fact(:meltdown).value).to eq(false)
    end
  end
end
