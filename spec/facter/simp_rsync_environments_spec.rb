require 'spec_helper'

describe "SIMP Rsync Environments" do
  rsync_env_dir = '/var/simp/rsync/environments'

  after :each do
    Facter.clear
  end

  context "if #{rsync_env_dir} present" do
    before :each do
      File.stubs(:directory?).at_least_once.returns(true)

      Dir.expects(:glob).with("#{rsync_env_dir}/*").at_least_once.returns(
        ["#{rsync_env_dir}/production", "#{rsync_env_dir}/simp"]
      )

      Facter.collection.load(:simp_rsync_environments)
    end

    it 'should return an array of environments' do
      expect(Facter.fact(:simp_rsync_environments).value).to contain_exactly('production', 'simp')
    end
  end

  context "if #{rsync_env_dir} absent" do
    before :each do
      File.stubs(:directory?).returns(false)

      Facter.collection.load(:simp_rsync_environments)
    end

    it 'should be nil' do
      expect(Facter.fact(:simp_rsync_environments)).to be_nil
    end
  end

  context "if #{rsync_env_dir} empty" do
    before :each do
      File.stubs(:directory?).returns(true)

      Dir.expects(:glob).with("#{rsync_env_dir}/*").at_least_once.returns([])

      Facter.collection.load(:simp_rsync_environments)
    end

    it 'should be empty' do
      expect(Facter.fact(:simp_rsync_environments).value).to be_empty
    end
  end
end
