# frozen_string_literal: true

require 'smart_proxy_salt/cli'
require 'smart_proxy_salt/rest'

module Proxy
  # SmartProxy Salt
  module Salt
    class NotFound < RuntimeError; end

    # Implement a SmartProxy plugin
    class Plugin < ::Proxy::Plugin
      plugin 'salt', Proxy::Salt::VERSION

      default_settings :autosign_file      => '/etc/salt/autosign.conf',
                       :autosign_key_file  => '/var/lib/foreman-proxy/salt/grains/autosign_key',
                       :salt_command_user  => 'root',
                       :use_api            => false,
                       :saltfile           => '/etc/foreman-proxy/settings.d/salt.saltfile'

      requires :dynflow, '>= 0.5.0'

      rackup_path File.expand_path('salt_http_config.ru', __dir__)

      load_classes do
        require 'smart_proxy_dynflow'
        require 'smart_proxy_salt/salt_runner'
        require 'smart_proxy_salt/salt_task_launcher'
      end

      load_dependency_injection_wirings do |_container_instance, _settings|
        Proxy::Dynflow::TaskLauncherRegistry.register('salt', SaltTaskLauncher)
      end
    end

    class << self
      def method_missing(m, *args, &block)
        # Use API, if it supports it, otherwise fallback to the CLI
        if Proxy::Salt::Plugin.settings.use_api && Proxy::Salt::Rest.respond_to?(m)
          Proxy::Salt::Rest.send(m, *args, &block)
        elsif Proxy::Salt::CLI.respond_to?(m)
          Proxy::Salt::CLI.send(m, *args, &block)
        elsif !Proxy::Salt::Plugin.settings.use_api && Proxy::Salt::Rest.respond_to?(m)
          raise NotImplementedError.new('You must enable the Salt API to use this feature.')
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        Proxy::Salt::Rest.respond_to?(method) || Proxy::Salt::CLI.respond_to?(method) || super
      end
    end
  end
end
