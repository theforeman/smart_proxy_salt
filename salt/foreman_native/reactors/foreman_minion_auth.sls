{% if data.get('act') == 'accept' %}
remove_autosign_key_local:
  runner.foreman.remove_authenticated_key:
    - minion: {{ data['id'] }}

notify_foreman_auth:
  runner.foreman.notify_authenticated:
    - minion: {{ data['id'] }}
{% endif %}
