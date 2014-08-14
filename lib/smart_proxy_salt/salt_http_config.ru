require 'smart_proxy_salt/salt_api'
map "/salt" do
run Proxy::Salt::Api
end
