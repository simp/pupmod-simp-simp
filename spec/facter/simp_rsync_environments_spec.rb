require 'spec_helper'

describe 'SIMP Rsync Environments' do
  after :each do
    LegacyFacter.clear
  end

  rsync_env_dir = '/var/simp/environments'

  context "if #{rsync_env_dir} present" do
    before :each do
      allow(File).to receive(:directory?).at_least(:once).and_return(true)

      # All the random that rspec itself does
      allow(Dir).to receive(:chdir).at_least(:once)

      allow(Dir).to receive(:chdir).with(rsync_env_dir).at_least(:once).and_return(true)

      allow(Dir).to receive(:glob).with('*/rsync').at_least(:once).and_return(['simp/rsync'])

      allow(Facter::Core::Execution).to receive(:exec).with("find -L simp -name '.shares'").at_least(:once).and_return('simp/rsync/.shares')

      allow(Dir).to receive(:glob).with('simp/rsync/*').at_least(:once).and_return([
                                                                                     'simp/rsync/Global/mcafee',
                                                                                     'simp/rsync/Global/clamav',
                                                                                   ])

      LegacyFacter.collection.load(:simp_rsync_environments)
    end

    it 'returns a Hash of environments' do
      expect(LegacyFacter.fact(:simp_rsync_environments).value).to eql({
                                                                         'simp' => {
                                                                           'id' => 'simp',
                                                                           'rsync' => {
                                                                             'id' => 'rsync',
                                                                             'global' => {
                                                                               'id' => 'Global',
                                                                               'shares' => [
                                                                                 'mcafee',
                                                                                 'clamav',
                                                                               ]
                                                                             }
                                                                           }
                                                                         }
                                                                       })
    end
  end

  context "if #{rsync_env_dir} absent" do
    before :each do
      allow(File).to receive(:directory?).and_return(false)

      LegacyFacter.collection.load(:simp_rsync_environments)
    end

    it 'is empty' do
      expect(LegacyFacter.fact(:simp_rsync_environments)).to be_nil
    end
  end

  context "if #{rsync_env_dir} empty" do
    before :each do
      allow(File).to receive(:directory?).and_return(true)

      allow(Dir).to receive(:chdir).at_least(:once)
      allow(Dir).to receive(:glob).with('*/rsync').at_least(:once).and_return(['simp/rsync'])

      allow(Facter::Core::Execution).to receive(:exec).with("find -L simp -name '.shares'").at_least(:once).and_return('')

      LegacyFacter.collection.load(:simp_rsync_environments)
    end

    it 'is empty' do
      expect(LegacyFacter.fact(:simp_rsync_environments).value).to be_empty
    end
  end
end
