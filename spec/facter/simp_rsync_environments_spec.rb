require 'spec_helper'

describe "SIMP Rsync Environments" do
  after :each do
    Facter.clear
  end

  rsync_env_dir = '/var/simp/environments'

  context "if #{rsync_env_dir} present" do
    before :each do
      File.stubs(:directory?).at_least_once.returns(true)

      # All the random that rspec itself does
      Dir.expects(:chdir).at_least_once

      Dir.expects(:chdir).with(rsync_env_dir).at_least_once.returns(true)

      Dir.expects(:glob).with('*/rsync').at_least_once.returns(['simp/rsync'])

      Facter::Core::Execution.expects(:exec).with("find -L simp -name '.shares'").at_least_once.returns("simp/rsync/.shares")

      Dir.expects(:glob).with('simp/rsync/*').at_least_once.returns([
        'simp/rsync/Global/mcafee',
        'simp/rsync/Global/clamav'
      ])

      Facter.collection.load(:simp_rsync_environments)
    end

    it 'should return a Hash of environments' do
      expect(Facter.fact(:simp_rsync_environments).value).to eql({
          'simp' => {
            'id' => 'simp',
            'rsync' => {
              'id' => 'rsync',
              'global' => {
                'id' => 'Global',
                'shares' => [
                  'mcafee',
                  'clamav'
                ]
              }
            }
          }
        })
    end
  end

  context "if #{rsync_env_dir} absent" do
    before :each do
      File.stubs(:directory?).returns(false)

      Facter.collection.load(:simp_rsync_environments)
    end

    it 'should be empty' do
      expect(Facter.fact(:simp_rsync_environments)).to be_nil
    end
  end

  context "if #{rsync_env_dir} empty" do
    before :each do
      File.stubs(:directory?).returns(true)

      Dir.expects(:chdir).at_least_once
      Dir.expects(:glob).with('*/rsync').at_least_once.returns(['simp/rsync'])

      Facter::Core::Execution.expects(:exec).with("find -L simp -name '.shares'").at_least_once.returns('')

      Facter.collection.load(:simp_rsync_environments)
    end

    it 'should be empty' do
      expect(Facter.fact(:simp_rsync_environments).value).to be_empty
    end
  end
end
