# frozen_string_literal: true

require 'smart_proxy_dynflow/runner/base'
require 'smart_proxy_salt/api_request'

module Proxy
  module Salt
    # Submit jobs via Salt API
    class SaltApiRunner < Proxy::Dynflow::Runner::Base
      DEFAULT_REFRESH_INTERVAL = 2

      attr_reader :jid

      def initialize(options, suspended_action)
        super(options, :suspended_action => suspended_action)
        @options = options
        @pending_minions = nil
        @killed = false
      end

      def start
        target = @options['name']
        script = @options['script']

        logger.debug("SaltApiRunner: state.template_str on #{target}")
        response = Proxy::Salt::ApiRequest.new.post('/run', :client => 'local_async', :tgt => target, :fun => 'state.template_str', :arg => [script])

        ret = response.dig('return', 0) || {}
        @jid = ret['jid']
        @pending_minions = Array(ret['minions']).dup

        # get jid so dynflow can work with the data
        publish_data("jid: #{@jid}\n", 'stdout')

        if @jid.nil? || @pending_minions.empty?
          publish_data("Salt API returned no jid/minions for #{target}: #{response.inspect}\n", 'stderr')
          publish_exit_status(1)
        end
      rescue StandardError => e
        publish_exception('Failed to start Salt job via API', e)
      end

      def refresh
        return if @jid.nil? || @pending_minions.nil? || @pending_minions.empty?
        return if @killed

        response = Proxy::Salt::ApiRequest.new.post('/run', :client => 'runner', :fun => 'jobs.lookup_jid', :arg => [@jid])
        results = response.dig('return', 0) || {}

        results.each do |minion, payload|
          next unless @pending_minions.include?(minion)

          publish_data(format_minion_result(minion, payload), 'stdout')
          @pending_minions.delete(minion)
        end

        return unless @pending_minions.empty?

        publish_exit_status(any_failure?(results) ? 1 : 0)
      rescue StandardError => e
        publish_exception('Failed to refresh Salt job via API', e)
      end

      def kill
        @killed = true
        publish_data("== TASK ABORTED BY USER ==\n", 'stdout')
        if @jid
          begin
            Proxy::Salt::ApiRequest.new.post('/run', :client => 'runner', :fun => 'jobs.kill_job', :arg => [@jid])
          rescue StandardError => e
            logger.warn("kill_job(#{@jid}) failed: #{e}")
          end
        end
        publish_exit_status(1)
      end

      private

      def format_minion_result(minion, payload)
        body = if payload.is_a?(Hash)
                 begin
                   JSON.pretty_generate(payload)
                 rescue StandardError
                   payload.inspect
                 end
               else
                 payload.to_s
               end
        "#{minion}:\n#{body}\n"
      end

      def any_failure?(results)
        results.values.any? do |per_minion|
          case per_minion
          when Hash
            per_minion.values.any? { |s| s.is_a?(Hash) && s['result'] == false }
          when Array
            true
          else
            true
          end
        end
      end
    end
  end
end
