#lib = File.expand_path('../lib', __FILE__)
#$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'smart_proxy_salt/version'

Gem::Specification.new do |s|
  s.name = 'smart_proxy_salt'
  s.version = '0.0.1'
#  s.version = Proxy::Salt::VERSION

  s.summary = "SaltStack Plug-In for Foreman's Smart Proxy"
  s.description = "SaltStack Plug-In for Foreman's Smart Proxy"
  s.authors = ['Stephen Benjamin']
  s.email = 'stephen@redhat.com'
  s.files = Dir['{lib,settings.d,bundler.d}/**/*'] + ['README', 'LICENSE']
  s.homepage = 'http://github.com/stbenjam/smart-proxy_salt'
  s.license = 'GPLv3'
end
