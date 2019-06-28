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
      end
    end
  end
end
