require 'sinatra'
require 'smart_proxy_salt/salt'
require 'smart_proxy_salt/salt_main'

module Proxy::Salt
  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers

    post "/autosign/:host" do
      content_type :json
      begin
        Proxy::Salt.autosign_create(params[:host]).to_json
      rescue => e
        log_halt 406, "Failed to create autosign for #{params[:host]}: #{e}"
      end
    end

    delete "/autosign/:host" do
      content_type :json
      begin
        Proxy::Salt.autosign_remove(params[:host]).to_json
      rescue Proxy::Salt::NotFound => e
        log_halt 404, "#{e}"
      rescue => e
        log_halt 406, "Failed to remove autosign for #{params[:host]}: #{e}"
      end
    end

    post "/highstate/:host" do
      content_type :json
      begin
        log_halt 500, "Failed salt run for #{params[:host]}: Check Log files" unless Proxy::Salt.highstate(params[:host]).to_json
      rescue => e
        log_halt 406, "Failed salt run for #{params[:host]}: #{e}"
      end
    end
  end
end
