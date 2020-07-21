{% if 'act' in data and 'id' in data %}
{% if data['act'] == 'accept' %}
{% if salt['saltutil.runner']('foreman_file.check_key', (data['id'], 100)) == True %}
{%- do salt.log.info('Minion authenticated successfully, starting HTTPS request to delete autosign key.') -%}
remove_autosign_key_custom_runner:
  runner.foreman_https.query_cert:
    - method: PUT
    - host: or.deploy2.dev.atix
    - path: /salt/api/v2/salt_autosign_auth?name={{ data['id'] }}
    - cert: /etc/pki/katello/puppet/puppet_client.crt
    - key: /etc/pki/katello/puppet/puppet_client.key
    - port: 443
# call_foreman_salt_custom_runner:
#   runner.foreman_https.query_user:
#     - method: PUT
#     - host: or.deploy2.dev.atix
#     - path: /salt/api/v2/salt_autosign_auth?name={{ data['id']  }}
#     - username: admin
#     - password: changeme
#     - port: 443
{% endif %}
{% endif %}
{% endif %}
