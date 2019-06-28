# frozen_string_literal: true

source 'https://rubygems.org'
gemspec :name => 'smart_proxy_salt'

group :development do
  gem 'smart_proxy', :git => 'https://github.com/theforeman/smart-proxy', :branch => 'develop'
end

group :test do
  gem 'webmock'
  if RUBY_VERSION < '2.1'
    gem 'public_suffix', '< 3'
  else
    gem 'public_suffix'
  end
  if RUBY_VERSION < '2.2'
    gem 'rack-test', '< 0.8'
  else
    gem 'rack-test'
  end
end

if RUBY_VERSION < '2.2'
  gem 'sinatra', '< 2'
  gem 'rack', '>= 1.1', '< 2.0.0'
else
  gem 'sinatra'
  gem 'rack', '>= 1.1'
end
