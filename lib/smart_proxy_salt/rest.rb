require 'json'
require 'smart_proxy_salt/api_request'

module Proxy::Salt::Rest
  extend ::Proxy::Log
  extend ::Proxy::Util

  class << self
    def environments_list
      Proxy::Salt::ApiRequest.new.post('/run', :fun => 'fileserver.envs', :client => 'runner')['return'][0].to_s
    end

    def states_list(environment)
      states = []
      files = Proxy::Salt::ApiRequest.new.post('/run', :fun => 'fileserver.file_list',
                                   :saltenv => environment,
                                   :client => 'runner')['return'][0]

      files.each do |file|
        if file =~ /\.sls\Z/ && file != "top.sls"
          states << file.gsub('.sls', '').
                         gsub('/init', '').
                         chomp('/').
                         gsub('/', '.')
        end
      end

      states.to_s
    end
  end
end
