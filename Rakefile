# frozen_string_literal: true

require 'rake'
require 'rake/testtask'
require 'rake/clean'
CLOBBER.include 'pkg'

namespace 'smart_proxy_salt' do
  require 'bundler/gem_helper'
  Bundler::GemHelper.install_tasks(:name => 'smart_proxy_salt')
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test Salt plugin'
Rake::TestTask.new(:test) do |t|
  t.libs << '.'
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

require 'rubocop/rake_task'

desc 'Run RuboCop on the lib directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['bin/foreman-node', 'lib/**/*.rb', 'test/**/*.rb']
  task.fail_on_error = false
end

begin
  require 'ci/reporter/rake/test_unit'
rescue LoadError
  # test group not enabled
else
  namespace :jenkins do
    desc nil # No description means it's not listed in rake -T
    task unit: ['ci:setup:testunit', :test]
  end
end
