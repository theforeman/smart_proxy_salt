# frozen_string_literal: true

require 'sinatra'
require 'smart_proxy_salt/salt'

module Proxy
  module Salt
    # Implement the SmartProxy API
    class Api < ::Sinatra::Base
      include ::Proxy::Log
      helpers ::Proxy::Helpers
      authorize_with_trusted_hosts

      post '/autosign/:host' do
        content_type :json
        begin
          Proxy::Salt.autosign_create(params[:host]).to_json
        rescue Exception => e
          log_halt 406, "Failed to create autosign for #{params[:host]}: #{e}"
        end
      end

      delete '/autosign/:host' do
        content_type :json
        begin
          Proxy::Salt.autosign_remove(params[:host]).to_json
        rescue Proxy::Salt::NotFound => e
          log_halt 404, e.to_s
        rescue Exception => e
          log_halt 406, "Failed to remove autosign for #{params[:host]}: #{e}"
        end
      end

      get '/autosign' do
        content_type :json
        begin
          Proxy::Salt.autosign_list.to_json
        rescue Exception => e
          log_halt 406, "Failed to list autosign entries: #{e}"
        end
      end

      get '/environments' do
        content_type :json
        begin
          Proxy::Salt.environments_list
        rescue Exception => e
          log_halt 406, "Failed to list environments: #{e}"
        end
      end

      get '/environments/:environment' do
        content_type :json
        begin
          Proxy::Salt.states_list params[:environment]
        rescue Proxy::Salt::NotFound => e
          log_halt 404, e.to_s
        rescue Exception => e
          log_halt 406, "Failed to list states for #{params[:host]}: #{e}"
        end
      end

      post '/highstate/:host' do
        content_type :json
        begin
          log_halt 500, "Failed salt run for #{params[:host]}: Check Log files" unless (result = Proxy::Salt.highstate(params[:host]))
          result
        rescue Exception => e
          log_halt 406, "Failed salt run for #{params[:host]}: #{e}"
        end
      end

      post '/refresh_pillar/:host' do
        content_type :json
        begin
          log_halt 500, "Failed salt run for #{params[:host]}: Check Log files" unless (result = Proxy::Salt.refresh_pillar(params[:host]))
          result
        rescue Exception => e
          log_halt 406, "Failed salt run for #{params[:host]}: #{e}"
        end
      end

      delete '/key/:host' do
        content_type :json
        begin
          Proxy::Salt.key_delete(params[:host])
        rescue Exception => e
          log_halt 406, "Failed delete salt key for #{params[:host]}: #{e}"
        end
      end

      post '/key/:host' do
        content_type :json
        begin
          Proxy::Salt.key_accept(params[:host])
        rescue Exception => e
          log_halt 406, "Failed to accept salt key for #{params[:host]}: #{e}"
        end
      end

      delete '/key/reject/:host' do
        content_type :json
        begin
          Proxy::Salt.key_reject(params[:host])
        rescue Exception => e
          log_halt 406, "Failed to reject salt key for #{params[:host]}: #{e}"
        end
      end

      get '/key' do
        content_type :json
        begin
          Proxy::Salt.key_list.to_json
        rescue Exception => e
          log_halt 406, "Failed to list keys: #{e}"
        end
      end
    end
  end
end
