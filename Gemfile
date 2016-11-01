# ------------------------------------------------------------------------------
# Environment variables:
#   SIMP_GEM_SERVERS | a space/comma delimited list of rubygem servers
#   PUPPET_VERSION   | specifies the version of the puppet gem to load
# ------------------------------------------------------------------------------
# NOTE: SIMP Puppet rake tasks support ruby 2.0 and ruby 2.1
# ------------------------------------------------------------------------------
puppetversion = ENV.key?('PUPPET_VERSION') ? "#{ENV['PUPPET_VERSION']}" : '~>4'
gem_sources   = ENV.key?('SIMP_GEM_SERVERS') ? ENV['SIMP_GEM_SERVERS'].split(/[, ]+/) : ['https://rubygems.org']

gem_sources.each { |gem_source| source gem_source }

group :test do
  gem "rake"
  gem 'puppet', puppetversion
  gem "rspec", '< 3.2.0'
  gem "rspec-puppet"
  gem "hiera-puppet-helper"
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "simp-rspec-puppet-facts", "~> 1.4"
  if ENV['SIMP_RAKE_HELPERS_VERSION']
    gem 'simp-rake-helpers', ENV['SIMP_RAKE_HELPERS_VERSION']
  else
    gem 'simp-rake-helpers', '~> 3.0'
  end
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "travish"
  gem "puppet-blacksmith"
  gem "guard-rake"
  gem 'pry'
  gem 'pry-doc'

  # `listen` is a dependency of `guard`
  # from `listen` 3.1+, `ruby_dep` requires Ruby version >= 2.2.3, ~> 2.2
  gem 'listen', '~> 3.0.6'
end

group :system_tests do
  #gem 'beaker'
  # Need this for SELinux workarounds until the PR gets accepted
  gem 'beaker'
  gem 'beaker-rspec'
  gem 'simp-beaker-helpers', '>= 1.0.5'
end
