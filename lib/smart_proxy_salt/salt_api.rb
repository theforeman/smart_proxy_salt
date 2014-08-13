require 'sinatra'
require 'smart_proxy_salt/salt'
require 'smart_proxy_salt/autosign'

module Proxy::Salt
  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers

    before do
      @autosign = Proxy::Salt::Autosign.new
    end

    post "/autosign/:host" do
      content_type :json
      begin
        @autosign.create(params[:host]).to_json
      rescue => e
        log_halt 406, "Failed to create autosign for #{params[:host]}: #{e}"
      end
    end

    delete "/autosign/:host" do
      content_type :json
      begin
        @autosign.remove(params[:host]).to_json
      rescue Proxy::Salt::NotFound => e
        log_halt 404, "#{e}"
      rescue => e
        log_halt 406, "Failed to remove autosign for #{params[:host]}: #{e}"
      end
    end
  end
end
