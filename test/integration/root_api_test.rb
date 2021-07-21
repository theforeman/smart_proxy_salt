require 'test_helper'
require 'json'
require 'mocha/test_unit'
require 'rack/test'
require 'root/root'
require 'root/root_v2_api'
require 'smart_proxy_dynflow'
require 'smart_proxy_salt'

class SaltApiFeaturesTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Proxy::PluginInitializer.new(Proxy::Plugins.instance).initialize_plugins
    Proxy::RootV2Api.new
  end

  def test_features
    Proxy::LegacyModuleLoader.any_instance.expects(:load_configuration_file).with('dynflow.yml').returns(enabled: true)
    Proxy::DefaultModuleLoader.any_instance.expects(:load_configuration_file).with('salt.yml').returns(enabled: true)

    get '/features'

    response = JSON.parse(last_response.body)

    mod = response['salt']
    refute_nil(mod)
    assert_equal('running', mod['state'], Proxy::LogBuffer::Buffer.instance.info[:failed_modules][:salt])
    assert_equal([], mod['capabilities'])
    assert_equal({}, mod['settings'])
  end

  def test_without_dynflow
    Proxy::LegacyModuleLoader.any_instance.expects(:load_configuration_file).with('dynflow.yml').returns(enabled: false)
    Proxy::DefaultModuleLoader.any_instance.expects(:load_configuration_file).with('salt.yml').returns(enabled: true)

    get '/features'

    response = JSON.parse(last_response.body)

    mod = response['salt']
    refute_nil(mod)
    assert_equal('failed', mod['state'], Proxy::LogBuffer::Buffer.instance.info[:failed_modules][:salt])
  end
end
