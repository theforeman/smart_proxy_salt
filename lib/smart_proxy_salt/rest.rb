# frozen_string_literal: true

require 'json'
require 'smart_proxy_salt/api_request'

module Proxy
  module Salt
    # Rest Salt API methods
    module Rest
      extend ::Proxy::Log
      extend ::Proxy::Util

      class << self
        def environments_list
          JSON.dump(Proxy::Salt::ApiRequest.new.post('/run', :fun => 'fileserver.envs', :client => 'runner')['return'][0])
        end

        def states_list(environment)
          states = []
          files = Proxy::Salt::ApiRequest.new.post('/run', :fun => 'fileserver.file_list',
                                                           :saltenv => environment,
                                                           :client => 'runner')['return'][0]

          files.each do |file|
            next unless file =~ /\.sls\Z/ && file != 'top.sls'

            states << file.gsub('.sls', '').gsub('/init', '').chomp('/').tr('/', '.')
          end

          JSON.dump(states)
        end

        def highstate(host)
          result = Proxy::Salt::ApiRequest.new.post('/run',
                                                    :client => 'local_async',
                                                    :tgt => host,
                                                    :fun => 'state.highstate')
          job = result.dig('return', 0)
          raise ApiError.new("Unexpected response from Salt API for highstate(#{host}): #{result.inspect}") unless job.is_a?(Hash)

          job
        end

        def key_delete(host)
          wheel_call('key.delete', :match => host)
        end

        def key_accept(host)
          wheel_call('key.accept', :match => host, :include_rejected => true)
        end

        def key_reject(host)
          wheel_call('key.reject', :match => host, :include_accepted => true)
        end

        # For this to work the autosign modules need to be present on the salt master

        def autosign_create_hostname(hostname)
          autosign_wheel('autosign.add_hostname', { :hostname => hostname }, 'Added hostname successfully.', 'Failed to add hostname.')
        end

        def autosign_remove_hostname(hostname)
          autosign_wheel('autosign.remove_hostname', { :hostname => hostname }, 'Removed hostname successfully.', 'Failed to remove hostname.')
        end

        def autosign_create_key(key)
          autosign_wheel('autosign.add_key', { :key => key }, 'Added key successfully.', 'Failed to add key.')
        end

        def autosign_remove_key(key)
          autosign_wheel('autosign.remove_key', { :key => key }, 'Removed key successfully.', 'Failed to remove key.')
        end

        def autosign_list
          response = Proxy::Salt::ApiRequest.new.post('/run', :client => 'wheel', :fun => 'autosign.list')
          result = response.dig('return', 0, 'data', 'return')
          result.is_a?(Array) ? result : []
        end

        def key_list
          response = Proxy::Salt::ApiRequest.new.post('/run', :client => 'wheel', :fun => 'key.finger', :match => '*')
          finger_data = response.dig('return', 0, 'data', 'return') || {}

          keys_hash = {}
          {
            'minions' => 'accepted',
            'minions_rejected' => 'rejected',
            'minions_pre' => 'unaccepted',
            'minions_denied' => 'denied'
          }.each do |bucket, state|
            (finger_data[bucket] || {}).each do |minion, fingerprint|
              keys_hash[minion] = { 'state' => state, 'fingerprint' => fingerprint }
            end
          end
          keys_hash
        end

        private

        def wheel_call(fun, opts = {})
          response = Proxy::Salt::ApiRequest.new.post('/run', opts.merge(:client => 'wheel', :fun => fun))
          response.dig('return', 0, 'data', 'success') ? true : false
        end

        def autosign_wheel(fun, args, ok_msg, err_msg)
          response = Proxy::Salt::ApiRequest.new.post('/run', args.merge(:client => 'wheel', :fun => fun))
          inner = response.dig('return', 0, 'data', 'return') || {}
          { :message => inner['success'] ? ok_msg : "#{err_msg} See smart proxy error log for more information." }
        end
      end
    end
  end
end
