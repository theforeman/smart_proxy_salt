require 'sinatra'
require 'smart_proxy_salt/salt'

module Proxy::Salt

  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers

    get '/autosign_file' do
      ::Salt::Plugin.settings.autosign_file
    end

  end
end
