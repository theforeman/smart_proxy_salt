{% if 'cmd' in data and data['cmd'] == '_return' and 'fun' in data and (
    data['fun'] == 'state.highstate' or (data['fun'] == 'state.template_str' and
                                         'fun_args' in data and
                                         data['fun_args'][0].startswith('state.highstate:')
)) %}
 foreman_report_upload:
  runner.foreman_report_upload.now:
    - args:
      - highstate: '{{data|json|base64_encode}}'
{% endif %}
