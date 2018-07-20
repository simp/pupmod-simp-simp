require 'simp/rake/pupmod/helpers'
require 'puppet-strings/tasks'


Simp::Rake::Pupmod::Helpers.new(File.dirname(__FILE__))

# Be sure to remove the rsync_share we have kludged into
# spec/fixtures/acceptance, by specifying a relative path in .fixtures.yml
Rake::Task[:spec_clean].enhance do
  require 'fileutils'
  FileUtils.rm_rf('spec/fixtures/acceptance')
end


# Fix non-modules fixtures that simp-rake-helpers can't handle when
# SIMP_RSPEC_PUPPETFILE or SIMP_RSPEC_MODULEPATH are set.
#
# MONKEY PATCH WARNING:  This is hideously fragile!!! It aliases an internal
# method in simp-rake-helpers.
class Simp::Rake::Pupmod::Helpers
  alias_method :orig_custom_fixtures_hook, :custom_fixtures_hook

  def custom_fixtures_hook(opts = {
    :short_name          => nil,
    :puppetfile          => nil,
    :modulepath          => nil,
    :local_fixtures_mods => nil,
  })

    if ENV['SIMP_RSPEC_FIXTURES_OVERRIDE'] == 'yes'
      # This will never work because simp-rake-helpers removes anything
      # that does not have a metadata.json file in spec/fixtures/modules.
      fail('SIMP_RSPEC_FIXTURES_OVERRIDE cannot be set for this project because of custom, non-module fixtures')
    end

    puts ">>> #{__FILE__}: Customizing fixtures not handle by simp-rake-helpers"

    # TODO Discover this based on a URL match instead of depending upon a
    # hardcoded hash
    assets = {
      'simp_environment'                => 'environment',
      '../acceptance/rsync_shares/simp' => 'rsync_data'
    }

    # Adjust the names of the assets to match what is in a simp-core Puppetfile
    assets.each do |orig_name, puppetfile_name|
      opts[:local_fixtures_mods].delete(orig_name)
      opts[:local_fixtures_mods] << puppetfile_name
    end

    # This temporary fixtures file has just about everything we need, except,
    # the names for the non-module assets are wrong and the acceptance tests
    # won't work unless these are reverted back to what was in the
    # .fixtures.yml file.
    puts '>>>>> Generating custom fixtures file'
    custom_fixtures_path = orig_custom_fixtures_hook(opts)

    # Revert the non-module entries back to their original names
    custom_fixtures = YAML.load_file(custom_fixtures_path)
    puts ">>>>> Fixing custom fixtures file #{custom_fixtures_path}"
    assets.each do |orig_name, puppetfile_name|
      entry = custom_fixtures['fixtures']['repositories'][puppetfile_name].dup
      custom_fixtures['fixtures']['repositories'].delete(puppetfile_name)
      custom_fixtures['fixtures']['repositories'][orig_name] = entry
    end
    File.open(custom_fixtures_path, 'w') { |file| file.write custom_fixtures.to_yaml }

    custom_fixtures_path
  end
end
