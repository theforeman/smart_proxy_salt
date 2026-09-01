{% if data.get('fun') == 'state.highstate' %}
upload_facts_post_highstate:
  runner.foreman.upload_grains:
    - minion: {{ data['id'] }}
{% endif %}
