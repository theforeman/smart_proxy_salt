require 'sinatra'
require 'smart_proxy_salt/salt'
require 'smart_proxy_salt/salt_main'

module Proxy::Salt
  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers
    authorize_with_ssl_client

    post '/autosign/:host' do
      content_type :json
      begin
        Proxy::Salt.autosign_create(params[:host]).to_json
      rescue => e
        log_halt 406, "Failed to create autosign for #{params[:host]}: #{e}"
      end
    end

    delete '/autosign/:host' do
      content_type :json
      begin
        Proxy::Salt.autosign_remove(params[:host]).to_json
      rescue Proxy::Salt::NotFound => e
        log_halt 404, "#{e}"
      rescue => e
        log_halt 406, "Failed to remove autosign for #{params[:host]}: #{e}"
      end
    end

    get '/autosign' do
      content_type :json
      begin
        Proxy::Salt::autosign_list.to_json
      rescue => e
        log_halt 406, "Failed to list autosign entries: #{e}"
      end
    end

    post '/highstate/:host' do
      content_type :json
      begin
        log_halt 500, "Failed salt run for #{params[:host]}: Check Log files" unless (result = Proxy::Salt.highstate(params[:host]))
        result
      rescue => e
        log_halt 406, "Failed salt run for #{params[:host]}: #{e}"
      end
    end

    delete '/key/:host' do
      content_type :json
      begin
        Proxy::Salt.key_delete(params[:host])
      rescue => e
        log_halt 406, "Failed delete salt key for #{params[:host]}: #{e}"
      end
    end

    post '/key/:host' do
      content_type :json
      begin
        Proxy::Salt::key_accept(params[:host])
      rescue => e
        log_halt 406, "Failed to accept salt key for #{params[:host]}: #{e}"
      end
    end

    delete '/key/reject/:host' do
      content_type :json
      begin
        Proxy::Salt::key_reject(params[:host])
      rescue => e
        log_halt 406, "Failed to reject salt key for #{params[:host]}: #{e}"
      end
    end

    get '/key' do
      content_type :json
      begin
        Proxy::Salt::key_list.to_json
      rescue => e
        log_halt 406, "Failed to list keys: #{e}"
      end
    end

  end
end
