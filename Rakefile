require 'simp/rake/pupmod/helpers'
require 'puppet-strings/tasks'


Simp::Rake::Pupmod::Helpers.new(File.dirname(__FILE__))

# Be sure to remove the rsync_share we have kludged into
# spec/fixtures/acceptance, by specifying a relative path in .fixtures.yml
Rake::Task[:spec_clean].enhance do
  require 'fileutils'
  FileUtils.rm_rf('spec/fixtures/acceptance')
end

if ENV['SIMP_RSPEC_FIXTURES_OVERRIDE'] == 'yes'
  # This will never work because simp-rake-helpers removes anything
  # that does not have a metadata.json file in spec/fixtures/modules.
  fail('SIMP_RSPEC_FIXTURES_OVERRIDE cannot be set for this project because of custom, non-module fixtures')
end
