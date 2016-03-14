require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet/version'
require 'puppet/vendor/semantic/lib/semantic' unless Puppet.version.to_f < 3.6
require 'puppet-syntax/tasks/puppet-syntax'
require 'puppet-lint/tasks/puppet-lint'
require 'parallel_tests/cli'

# These gems aren't always present, for instance
# on Travis with --without development
begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError
end


# Lint & Syntax exclusions
exclude_paths = [
  "bundle/**/*",
  "pkg/**/*",
  "dist/**/*",
  "vendor/**/*",
  "spec/**/*",
]
PuppetSyntax.exclude_paths = exclude_paths

# See: https://github.com/rodjek/puppet-lint/pull/397
Rake::Task[:lint].clear
PuppetLint.configuration.ignore_paths = exclude_paths
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = PuppetLint.configuration.ignore_paths
end

begin
  require 'simp/rake/pkg'
  Simp::Rake::Pkg.new( File.dirname( __FILE__ ) ) do | t |
    t.clean_list << "#{t.base_dir}/spec/fixtures/hieradata/hiera.yaml"
  end
rescue LoadError
  puts "== WARNING: Gem simp-rake-helpers not found, pkg: tasks cannot be run! =="
end

begin
  require 'simp/rake/beaker'
  Simp::Rake::Beaker.new( File.dirname( __FILE__ ) )
rescue LoadError
  # Ignoring this for now since all of these are currently convenience methods.
end

desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = 'spec/acceptance'
end

desc "Populate CONTRIBUTORS file"
task :contributors do
  system("git log --format='%aN' | sort -u > CONTRIBUTORS")
end

task :metadata do
  sh "metadata-json-lint metadata.json"
end

desc "Run syntax, lint, and spec tests."
task :test => [
  :syntax,
  :lint,
  :spec_parallel,
  :metadata,
]

desc <<-EOM
Run parallel spec tests.

This will NOT run acceptance tests.
EOM
task :spec_parallel do
  test_targets = ['spec/classes', 'spec/defines', 'spec/unit', 'spec/functions']

  if ENV['SIMP_PARALLEL_TARGETS']
    test_targets += ENV['SIMP_PARALLEL_TARGETS'].split
  end

  test_targets.delete_if{|dir| !File.directory?(dir)}

  Rake::Task[:spec_prep].invoke
  ParallelTests::CLI.new.run('--type test -t rspec'.split + test_targets)
  Rake::Task[:spec_clean].invoke
end
