# frozen_string_literal: true

require 'test_helper'
require 'json'
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

  def test_highstate
    stub_request(:post, "#{@salt_rest_api}/run").with(
      :body => { 'client' => 'local_async',
                 'tgt' => 'salt_host',
                 'fun' => 'state.highstate',
                 'eauth' => nil,
                 'password' => nil,
                 'username' => nil }
    ).to_return(:status => 200, :body => '{"return": [{"jid": "20260522210000000001", "minions": ["salt_host"]}]}')

    post '/highstate/salt_host'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
  end

  def test_highstate_unexpected_response
    stub_request(:post, "#{@salt_rest_api}/run").with(
      :body => { 'client' => 'local_async',
                 'tgt' => 'salt_host',
                 'fun' => 'state.highstate',
                 'eauth' => nil,
                 'password' => nil,
                 'username' => nil }
    ).to_return(:status => 200, :body => '{"return": [null]}')

    post '/highstate/salt_host'
    assert_equal 406, last_response.status
  end

  def stub_wheel(fun, extra_body, response_body)
    stub_request(:post, "#{@salt_rest_api}/run").with(
      :body => { 'client' => 'wheel', 'fun' => fun,
                 'eauth' => nil, 'password' => nil, 'username' => nil }.merge(extra_body)
    ).to_return(:status => 200, :body => response_body)
  end

  def test_key_delete
    stub_wheel('key.delete', { 'match' => 'salt_host' },
               '{"return": [{"data": {"success": true}}]}')
    delete '/key/salt_host'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
  end

  def test_key_accept
    stub_wheel('key.accept', { 'match' => 'salt_host', 'include_rejected' => 'true' },
               '{"return": [{"data": {"success": true}}]}')
    post '/key/salt_host'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
  end

  def test_key_reject
    stub_wheel('key.reject', { 'match' => 'salt_host', 'include_accepted' => 'true' },
               '{"return": [{"data": {"success": true}}]}')
    delete '/key/reject/salt_host'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
  end

  def test_autosign_create_hostname
    stub_wheel('autosign.add_hostname', { 'hostname' => 'bdf9f052723195aa35f94a4bc5512fdc' },
               '{"return": [{"data": {"return": {"success": true}}}]}')
    post '/autosign/bdf9f052723195aa35f94a4bc5512fdc'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Added hostname successfully."}', last_response.body)
  end

  def test_autosign_create_hostname_failure
    stub_wheel('autosign.add_hostname', { 'hostname' => 'badhost' },
               '{"return": [{"data": {"return": {"success": false}}}]}')
    post '/autosign/badhost'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_includes(last_response.body, 'Failed to add hostname.')
  end

  def test_autosign_remove_hostname
    stub_wheel('autosign.remove_hostname', { 'hostname' => 'bdf9f052723195aa35f94a4bc5512fdc' },
               '{"return": [{"data": {"return": {"success": true}}}]}')
    delete '/autosign/bdf9f052723195aa35f94a4bc5512fdc'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Removed hostname successfully."}', last_response.body)
  end

  def test_autosign_create_key
    stub_wheel('autosign.add_key', { 'key' => 'lulz' },
               '{"return": [{"data": {"return": {"success": true}}}]}')
    post '/autosign_key/lulz'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Added key successfully."}', last_response.body)
  end

  def test_autosign_remove_key
    stub_wheel('autosign.remove_key', { 'key' => 'lulz' },
               '{"return": [{"data": {"return": {"success": true}}}]}')
    delete '/autosign_key/lulz'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Removed key successfully."}', last_response.body)
  end

  def test_autosign_list
    stub_wheel('autosign.list', {},
               '{"return": [{"data": {"return": ["bdf9f052723195aa35f94a4bc5512fdc","03e3cb85330f403d75f315166e93f123"]}}]}')
    get '/autosign'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('["bdf9f052723195aa35f94a4bc5512fdc","03e3cb85330f403d75f315166e93f123"]', last_response.body)
  end

  def test_autosign_list_empty
    stub_wheel('autosign.list', {},
               '{"return": [{"data": {"return": null}}]}')
    get '/autosign'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('[]', last_response.body)
  end

  def test_key_list
    finger = '{
      "minions": {
        "centos8-devel": "47:8f:ba:ed:99:44:da:5a:26:f9:34:a6:36:d8:ab:50:b8:11:63:fd:21:95:22:91:d0:8b:1c:16:a3:ed:22:b7"
      },
      "minions_pre": {
        "debian9.devel": "23:91:4e:c1:a2:99:6b:b4:48:43:0c:7d:88:ea:22:5e:22:7e:f5:f7:ab:e1:9e:52:c1:20:75:a0:1a:d5:47:22"
      },
      "minions_rejected": {
        "rhel7.devel": "80:88:11:df:4a:6c:69:17:73:f5:10:22:14:de:a2:76:ea:ab:0e:41:47:41:27:1b:dc:6c:5e:10:ab:1f:d7:c3"
      },
      "minions_denied": {
        "evil.devel": "ff:ff:ff:ff"
      }
    }'
    stub_wheel('key.finger', { 'match' => '*' },
               "{\"return\": [{\"data\": {\"return\": #{finger}}}]}")
    get '/key'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    parsed = JSON.parse(last_response.body)
    assert_equal('accepted',   parsed['centos8-devel']['state'])
    assert_equal('unaccepted', parsed['debian9.devel']['state'])
    assert_equal('rejected',   parsed['rhel7.devel']['state'])
    assert_equal('denied',     parsed['evil.devel']['state'])
  end

  def test_key_list_empty
    stub_wheel('key.finger', { 'match' => '*' },
               '{"return": [{"data": {"return": {}}}]}')
    get '/key'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{}', last_response.body)
  end
end
