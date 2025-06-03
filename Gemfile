# frozen_string_literal: true

source 'https://rubygems.org'
gemspec :name => 'smart_proxy_salt'

group :rubocop do
  gem 'rubocop', '~> 1.28.0'
  gem 'rubocop-performance'
  gem 'rubocop-rake'
end

group :test do
  gem 'mocha', '~> 1'
  gem 'rack-test'
  gem 'rake', '~> 13'
  gem 'smart_proxy', github: 'theforeman/smart-proxy', branch: ENV.fetch('SMART_PROXY_BRANCH', 'develop')
  gem 'test-unit', '~> 3'
  gem 'webmock', '~> 1'
end
