require File.expand_path('../lib/smart_proxy_salt/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'smart_proxy_salt'
  s.version = Proxy::Salt::VERSION

  s.summary = "SaltStack Plug-In for Foreman's Smart Proxy"
  s.description = "SaltStack Plug-In for Foreman's Smart Proxy"
  s.authors = ['Michael Moll', 'Stephen Benjamin']
  s.email = 'foreman-dev@googlegroups.com'
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.files = Dir['{bin,cron,etc,lib,settings.d,bundler.d}/**/*'] + s.extra_rdoc_files
  s.executables = s.files.grep(%r{^bin/}) { |file| File.basename(file) }
  s.homepage = 'https://github.com/theforeman/smart_proxy_salt'
  s.license = 'GPLv3'
end
