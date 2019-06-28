# -*- coding: utf-8 -*-
require File.expand_path('../lib/smart_proxy_salt_core/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'smart_proxy_salt_core'
  s.version     = SmartProxySaltCore::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Adam Ruzicka']
  s.email       = ['aruzicka@redhat.com']
  s.homepage    = 'https://github.com/theforeman/smart_proxy_salt'
  s.summary     = 'Smart Proxy Salt - core bits'
  s.description = <<DESC
  Salt remote execution provider code for Foreman-Proxy
DESC

  s.files = Dir['lib/smart_proxy_salt_core/**/*'] +
            ['lib/smart_proxy_salt_core.rb', 'LICENSE']

  s.add_runtime_dependency('foreman-tasks-core', '>= 0.3.1')
end
