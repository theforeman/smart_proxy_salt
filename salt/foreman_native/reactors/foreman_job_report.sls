{%- set specs = opts.get('foreman', {}).get('upload_states', ['state.highstate']) -%}
{%- set fun = data.get('fun', '') -%}
{%- set allowed_funs = [] -%}
{%- for spec in specs -%}
  {%- do allowed_funs.append(spec.split(None, 1)[0]) -%}
{%- endfor -%}
{%- if fun == 'state.template_str' or fun in allowed_funs %}
upload_job_report:
  runner.foreman.upload_job_report:
    - event_data: {{ data|json }}
{%- endif %}
