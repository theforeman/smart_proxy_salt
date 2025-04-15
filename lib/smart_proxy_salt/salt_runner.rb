# frozen_string_literal: true

require 'smart_proxy_dynflow/runner/base'
require 'smart_proxy_dynflow/runner/command_runner'

module Proxy
  module Salt
    # Implements the SaltRunner to be used by foreman_remote_execution
    class SaltRunner < Proxy::Dynflow::Runner::CommandRunner
      DEFAULT_REFRESH_INTERVAL = 1

      attr_reader :jid

      def initialize(options, suspended_action)
        super(options, :suspended_action => suspended_action)
        @options = options
      end

      def start
        command = generate_command
        logger.debug("Running command '#{command.join(' ')}'")
        initialize_command(*command)
      end

      def kill
        publish_data('== TASK ABORTED BY USER ==', 'stdout')
        publish_exit_status(1)
        ::Process.kill('SIGTERM', @command_pid)
      end

      def publish_data(data, type)
        if @jid.nil? && (match = data.match(/jid: ([0-9]+)/))
          @jid = match[1]
        end
        super
      end

      def publish_exit_status(status)
        # If there was no salt job associated with this run, mark the job as failed
        status = 1 if @jid.nil?
        super status
      end

      private

      def generate_command
        saltfile_path = ::Proxy::Salt::Plugin.settings[:saltfile]
        command = %w[sudo salt --show-jid]
        command << "--saltfile=#{saltfile_path}" if File.file?(saltfile_path)
        command << @options['name']
        command << 'state.template_str'
        command << @options['script']
        command
      end
    end
  end
end
