# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'webmock/test_unit'
require 'mocha/test_unit'
require 'dynflow'
require 'smart_proxy_dynflow/runner'
require 'smart_proxy_salt/salt'
require 'smart_proxy_salt/salt_api_runner'

module Proxy
  module Salt
    class SaltApiRunnerTest < Test::Unit::TestCase
      def setup
        @salt_rest_api = 'http://localhost/salt_rest_api'
        Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true)
        @runner = SaltApiRunner.new({ 'name' => 'salt_host', 'script' => 'echo test' },
                                    :suspended_action => nil)
      end

      def test_start_sets_jid_and_pending_minions
        stub_start('return' => [{ 'jid' => '20260901000000000001', 'minions' => ['salt_host'] }])
        @runner.start
        assert_equal '20260901000000000001', @runner.jid
        assert_nil exit_status
      end

      def test_start_without_jid_publishes_failure
        stub_start('return' => [{}])
        @runner.start
        assert_equal 1, exit_status
      end

      def test_start_with_unexpected_payload_publishes_failure
        stub_start('unexpected' => 'payload')
        @runner.start
        assert_equal 1, exit_status
      end

      def test_start_with_api_error_publishes_failure
        stub_request(:post, "#{@salt_rest_api}/run")
          .with(:body => hash_including('fun' => 'state.template_str'))
          .to_return(:status => 500, :body => 'Unknown salt api error')
        @runner.start
        assert_equal 'EXCEPTION', exit_status
      end

      def test_refresh_success
        start_job(['salt_host'])
        stub_lookup('return' => [{ 'salt_host' => { 'state1' => { 'result' => true } } }])
        @runner.refresh
        assert_equal 0, exit_status
      end

      def test_refresh_failed_state_publishes_failure
        start_job(['salt_host'])
        stub_lookup('return' => [{ 'salt_host' => { 'state1' => { 'result' => false } } }])
        @runner.refresh
        assert_equal 1, exit_status
      end

      def test_refresh_waits_for_all_minions
        start_job(%w[salt_host other_host])
        stub_lookup('return' => [{ 'salt_host' => { 'state1' => { 'result' => true } } }])
        @runner.refresh
        assert_nil exit_status

        stub_lookup('return' => [{ 'other_host' => { 'state1' => { 'result' => true } } }])
        @runner.refresh
        assert_equal 0, exit_status
      end

      def test_kill_aborts_job
        start_job(['salt_host'])
        kill_stub = stub_request(:post, "#{@salt_rest_api}/run")
                    .with(:body => hash_including('fun' => 'jobs.kill_job'))
                    .to_return(:status => 200, :body => '{"return": [{}]}')
        @runner.kill
        assert_equal 1, exit_status
        assert_requested kill_stub
      end

      private

      def start_job(minions)
        stub_start('return' => [{ 'jid' => '1', 'minions' => minions }])
        @runner.start
        @runner.generate_updates
      end

      def stub_start(body)
        stub_request(:post, "#{@salt_rest_api}/run")
          .with(:body => hash_including('fun' => 'state.template_str'))
          .to_return(:status => 200, :body => JSON.dump(body))
      end

      def stub_lookup(body)
        stub_request(:post, "#{@salt_rest_api}/run")
          .with(:body => hash_including('fun' => 'jobs.lookup_jid'))
          .to_return(:status => 200, :body => JSON.dump(body))
      end

      def exit_status
        update = @runner.generate_updates[{ :suspended_action => nil }]
        update&.exit_status
      end
    end
  end
end
