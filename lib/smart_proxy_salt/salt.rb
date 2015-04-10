require 'smart_proxy_salt/cli'
require 'smart_proxy_salt/rest'

module Proxy::Salt
  class NotFound < RuntimeError; end

  class Plugin < ::Proxy::Plugin
    plugin 'salt', Proxy::Salt::VERSION

    default_settings :autosign_file      => '/etc/salt/autosign.conf',
                     :salt_command_user  => 'root',
                     :use_api            => false

    http_rackup_path File.expand_path('salt_http_config.ru', File.expand_path('../', __FILE__))
    https_rackup_path File.expand_path('salt_http_config.ru', File.expand_path('../', __FILE__))
  end

  class << self
    def method_missing(m, *args, &block)
      # Use API, if it supports it, otherwise fallback to the CLI
      if Proxy::Salt::Plugin.settings.use_api && Proxy::Salt::Rest.respond_to?(m)
        Proxy::Salt::Rest.send(m, *args, &block)
      elsif Proxy::Salt::CLI.respond_to?(m)
        Proxy::Salt::CLI.send(m, *args, &block)
      elsif !Proxy::Salt::Plugin.settings.use_api && Proxy::Salt::Rest.respond_to?(m)
        raise NotImplementedError, 'You must enable the Salt API to use this feature.'
      else
        super
      end
    end
  end
end
