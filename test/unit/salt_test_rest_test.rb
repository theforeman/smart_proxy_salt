# frozen_string_literal: true

require 'test_helper'
require 'webmock/test_unit'
require 'mocha/test_unit'
require 'rack/test'

require 'smart_proxy_salt/salt'
require 'smart_proxy_salt/salt_api'

# smart_proxy_salt tests running via SaltStack Rest API
class SaltRestTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Proxy::Salt::Api.new
  end

  def setup
    @salt_rest_api = 'http://localhost/salt_rest_api'
    Proxy::Salt::Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true)
  end

  def test_rest_disabled_api
    Proxy::Salt::Plugin.load_test_settings(:api_url => nil, :use_api => false)
    get '/environments'
    assert_equal 406, last_response.status
  end

  def test_rest_missing_api
    wrong_rest_api = 'http://localhost/wrong_rest_api'
    Proxy::Salt::Plugin.load_test_settings(:api_url => wrong_rest_api, :use_api => true)
    get '/environments'
    assert_equal 406, last_response.status
  end

  def test_rest_invalid_uri
    invalid_rest_api = '://invalid_uri'
    Proxy::Salt::Plugin.load_test_settings(:api_url => invalid_rest_api, :use_api => true)
    get '/environments'
    assert_equal 406, last_response.status
  end

  def test_salt_environments
    stub_request(:post, "#{@salt_rest_api}/run").with(
      :body => { 'client' => 'runner',
                 'fun' => 'fileserver.envs',
                 'eauth' => nil,
                 'password' => nil,
                 'username' => nil }
    ).to_return(:status => 200, :body => '{"return": [["base", "dev"]]}')

    get '/environments'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('["base","dev"]', last_response.body)
  end

  def test_salt_states_list
    stub_request(:post, "#{@salt_rest_api}/run").with(
      :body => { 'client' => 'runner',
                 'fun' => 'fileserver.file_list',
                 'saltenv' => 'base',
                 'eauth' => nil,
                 'password' => nil,
                 'username' => nil }
    ).to_return(:status => 200, :body => '{"return": [["motd/init.sls", "motd/motd.template", "vim.sls"]]}')

    get '/environments/base'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('["motd","vim"]', last_response.body)
  end

  def test_salt_states_list_unknown_env
    stub_request(:post, "#{@salt_rest_api}/run").with(
      :body => { 'client' => 'runner',
                 'fun' => 'fileserver.file_list',
                 'saltenv' => 'development',
                 'eauth' => nil,
                 'password' => nil,
                 'username' => nil }
    ).to_return(:status => 200, :body => '{"return": [[]]}')

    get '/environments/development'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('[]', last_response.body)
  end

  def test_salt_states_list_api_error
    stub_request(:post, "#{@salt_rest_api}/run").with(
      :body => { 'client' => 'runner',
                 'fun' => 'fileserver.file_list',
                 'saltenv' => 'base',
                 'eauth' => nil,
                 'password' => nil,
                 'username' => nil }
    ).to_return(:status => 500, :body => 'Unknown salt api error')

    get '/environments/base'
    assert_equal 406, last_response.status
  end
end
