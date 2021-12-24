{% if 'act' in data and 'id' in data %}
{% if data['act'] == 'accept' %}
{% if salt['saltutil.runner']('foreman_file.check_key', (data['id'], 100)) == True %}
{%- do salt.log.info('Minion authenticated successfully, starting HTTPS request to delete autosign key.') -%}
remove_autosign_key_custom_runner:
  runner.foreman_https.remove_key:
    - minion: {{ data['id'] }}
{% endif %}
{% endif %}
{% endif %}
