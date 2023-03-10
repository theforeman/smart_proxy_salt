# frozen_string_literal: true

require 'test_helper'
require 'webmock/test_unit'
require 'mocha/test_unit'
require 'rack/test'
require 'tempfile'

require 'smart_proxy_salt/salt'
require 'smart_proxy_salt/salt_api'

# smart_proxy_salt tests running on CLI
class SaltCLITest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Proxy::Salt::Api.new
  end

  def setup
    @salt_rest_api = 'http://localhost/salt_rest_api'

    autosign_file = Tempfile.new('autosign_foreman_provisioning_key')
    autosign_file.puts('bdf9f052723195aa35f94a4bc5512fdc')
    autosign_file.puts('# Ignore this comment, please')
    autosign_file.puts('03e3cb85330f403d75f315166e93f123')
    autosign_file.close
    @autosign_file_path = autosign_file.path

    autosign_key_file = Tempfile.new('salt_autosign_authentication_key')
    autosign_key_file.puts('3ja9d1lablqz')
    autosign_key_file.puts('dfby1j37lbva')
    autosign_key_file.close
    @autosign_key_file_path = autosign_key_file.path

    Proxy::Salt::Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true, :autosign_file => @autosign_file_path, :autosign_key_file => @autosign_key_file_path)
    Proxy::Salt::CLI.stubs(:which).with('sudo').returns('/bin/sudo')
    Proxy::Salt::CLI.stubs(:which).with('salt-key').returns('/bin/salt-key')
    Proxy::Salt::CLI.stubs(:which).with('salt').returns('/bin/salt')
    File.stubs(:exist?).returns(true)
  end

  def test_key_delete
    Proxy::Salt::CLI.stubs(:shell_command).returns(true)
    delete '/key/salt_host'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
  end

  def test_key_reject
    Proxy::Salt::CLI.stubs(:shell_command).returns(true)
    delete '/key/reject/salt_host'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
  end

  def test_key_accept
    Proxy::Salt::CLI.stubs(:shell_command).returns(true)
    post '/key/salt_host'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
  end

  def test_key_list
    Proxy::Salt::CLI.stubs(:`).with('/bin/sudo -u root /bin/salt-key --finger-all --output=json').returns('{
      "local": {
        "master.pem": "11:d2:1a:94:2a:a2:12:59:b0:e3:30:da:33:18:ef:89:89:64:0a:30:fd:1c:8c:88:9e:6e:19:36:99:f1:91:22",
        "master.pub": "22:fb:64:3e:7e:10:73:22:c1:14:d0:ac:c0:66:a8:b4:00:6a:39:74:d5:ef:bb:fe:8c:69:96:5b:e0:b6:11:43"
      },
      "minions": {
        "centos8-devel": "47:8f:ba:ed:99:44:da:5a:26:f9:34:a6:36:d8:ab:50:b8:11:63:fd:21:95:22:91:d0:8b:1c:16:a3:ed:22:b7",
        "centos7.devel": "cd:87:a0:b6:cf:ce:d1:8a:a6:22:8c:b8:30:d1:22:0f:43:45:c5:08:3b:01:d2:81:cf:72:6f:fe:36:d7:59:bf"
      },
      "minions_rejected": {
        "ubuntu18.devel": "dd:0f:6b:88:1d:56:a3:de:c4:f3:d9:70:35:21:3f:55:de:c9:70:c3:b3:62:71:01:6d:2a:d4:6e:4e:2f:ab:d7",
        "rhel7.devel": "80:88:11:df:4a:6c:69:17:73:f5:10:22:14:de:a2:76:ea:ab:0e:41:47:41:27:1b:dc:6c:5e:10:ab:1f:d7:c3"
      },
      "minions_pre": {
        "debian9.devel": "23:91:4e:c1:a2:99:6b:b4:48:43:0c:7d:88:ea:22:5e:22:7e:f5:f7:ab:e1:9e:52:c1:20:75:a0:1a:d5:47:22"
      }
    }', system('/bin/true')) # system('/bin/true') is necessary so that $CHILD_STATUS is set to 0

    expected = {
      'centos8-devel' => { 'state' => 'accepted',   'fingerprint' => '47:8f:ba:ed:99:44:da:5a:26:f9:34:a6:36:d8:ab:50:b8:11:63:fd:21:95:22:91:d0:8b:1c:16:a3:ed:22:b7' },
      'centos7.devel' => { 'state' => 'accepted',   'fingerprint' => 'cd:87:a0:b6:cf:ce:d1:8a:a6:22:8c:b8:30:d1:22:0f:43:45:c5:08:3b:01:d2:81:cf:72:6f:fe:36:d7:59:bf' },
      'ubuntu18.devel' => { 'state' => 'rejected', 'fingerprint' => 'dd:0f:6b:88:1d:56:a3:de:c4:f3:d9:70:35:21:3f:55:de:c9:70:c3:b3:62:71:01:6d:2a:d4:6e:4e:2f:ab:d7' },
      'rhel7.devel' => { 'state' => 'rejected', 'fingerprint' => '80:88:11:df:4a:6c:69:17:73:f5:10:22:14:de:a2:76:ea:ab:0e:41:47:41:27:1b:dc:6c:5e:10:ab:1f:d7:c3' },
      'debian9.devel' => { 'state' => 'unaccepted', 'fingerprint' => '23:91:4e:c1:a2:99:6b:b4:48:43:0c:7d:88:ea:22:5e:22:7e:f5:f7:ab:e1:9e:52:c1:20:75:a0:1a:d5:47:22' }
    }

    get '/key'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal(expected.to_json, last_response.body)
  end

  def test_key_list_empty
    Proxy::Salt::CLI.stubs(:`).with('/bin/sudo -u root /bin/salt-key --finger-all --output=json').returns('{
    }', system('/bin/true')) # system('/bin/true') is necessary so that $CHILD_STATUS is set to 0

    expected = {}

    get '/key'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal(expected.to_json, last_response.body)
  end

  def test_run_highstate
    Proxy::Salt::CLI.stubs(:shell_command).returns(true)
    post '/highstate/salt_host'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
  end

  def test_autosign_access_to_non_existent_file
    Proxy::Salt::Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true, :autosign_file => 'create_non_existent_file')
    post '/autosign/bdf9f052723195aa35f94a4bc5512fdc'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    File.open('create_non_existent_file') do |file|
      lines = file.readlines
      assert_includes(lines, "bdf9f052723195aa35f94a4bc5512fdc\n")
    end
  end

  def test_autosign_access_to_uncreatable_file
    Proxy::Salt::Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true, :autosign_file => '/cannot/create/file')
    post '/autosign/bdf9f052723195aa35f94a4bc5512fdc'
    assert_equal(last_response.status, 406)
    assert_includes(last_response.body, 'Failed to create autosign for bdf9f052723195aa35f94a4bc5512fdc')
  end

  def test_autosign_list
    get '/autosign'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('["bdf9f052723195aa35f94a4bc5512fdc","03e3cb85330f403d75f315166e93f123"]', last_response.body)
  end

  def test_autosign_list_missing_file
    Proxy::Salt::Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true, :autosign_file => 'doesnt_exist')
    get '/autosign'
    assert_equal 406, last_response.status, "Last response should be 406 but is: #{last_response.status}"
  end

  def test_autosign_create
    post '/autosign/bdf9f052723195aa35f94a4bc5512fdc'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Added hostname successfully."}', last_response.body)
  end

  def test_autosign_delete
    delete '/autosign/bdf9f052723195aa35f94a4bc5512fdc'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Removed hostname successfully."}', last_response.body)
  end

  def test_autosign_delete_unknown_host
    delete '/autosign/unknown_host'
    assert last_response.ok?, "Last response should fail but was ok: #{last_response.body}"
    assert_equal('{"message":"Removed hostname successfully."}', last_response.body)
  end

  def test_autosign_key_create
    post '/autosign_key/lulz'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Added key successfully."}', last_response.body)
    File.open(@autosign_key_file_path) do |file|
      lines = file.readlines
      assert_includes(lines, "lulz\n")
    end
  end

  def test_autosign_key_create_double
    post '/autosign_key/lulz'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Added key successfully."}', last_response.body)
    post '/autosign_key/lulz'
    File.open(@autosign_key_file_path) do |file|
      lines = file.readlines
      assert_equal(lines[-1], "lulz\n")
      assert_equal(lines.length, 3)
    end
  end

  def test_autosign_key_create_missing_file
    Proxy::Salt::Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true, :autosign_key_file => 'create_me')
    post '/autosign_key/lulz'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Added key successfully."}', last_response.body)
    File.open('create_me') do |file|
      lines = file.readlines
      assert_includes(lines, "lulz\n")
    end
  end

  def test_autosign_key_create_uncreatable_file
    Proxy::Salt::Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true, :autosign_key_file => '/cannot/create/file')
    post '/autosign_key/lulz'
    assert_equal(406, last_response.status)
    assert(last_response.body.include?('Failed to create autosign key lulz'))
  end

  def test_autosign_key_delete
    delete '/autosign_key/dfby1j37lbva'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Removed key successfully."}', last_response.body)
    File.open(@autosign_key_file_path) do |file|
      lines = file.readlines
      assert_not_include(lines, "dfby1j37lbva\n")
    end
  end

  def test_autosign_key_delete_nonexistent
    delete '/autosign_key/nokey'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Removed key successfully."}', last_response.body)
  end

  def test_autosign_key_delete_missing_file
    Proxy::Salt::Plugin.load_test_settings(:api_url => @salt_rest_api, :use_api => true, :autosign_key_file => 'create_me')
    delete '/autosign_key/lulz'
    assert last_response.ok?, "Last response was not ok: #{last_response.body}"
    assert_equal('{"message":"Removed key successfully."}', last_response.body)
  end
end
