{% if 'cmd' in data and data['cmd'] == '_return' and 'fun' in data and data['fun'] == 'state.highstate' %}
foreman_report_upload:
  runner.foreman_report_upload.now:
    - args: 
      - highstate: '{{data|json}}'
{% endif %}
