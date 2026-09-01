{% if data.get('act') == 'accept' %}
foreman_upload_facts:
  runner.foreman.upload_grains:
    - minion: {{ data['id'] }}
{% endif %}
