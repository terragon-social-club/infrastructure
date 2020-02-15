{% set has_lp_running = salt['mine.get']('roles:logstash', 'private_ip', tgt_type='grain').items()|length > 0 %}

/usr/local/etc/metricbeat.yml:
  file.managed:
    - source: salt:///files/metricbeat/haproxy.jinja.yml
    - template: jinja
    - require:
      - pkg: beats

metricbeat:
{% if has_lp_running %}
  service.running:
    - enable: True
    - requires:
        - cmd: "metricbeat --path.config /usr/local/etc modules enable haproxy > /root/metricbeat-haproxy-enabled"
    - watch:
        - file: /usr/local/etc/metricbeat.yml
{% else %}
  service.dead:
    - enable: False
{% endif %}

{% if has_lp_running %}
"metricbeat --path.config /usr/local/etc modules enable haproxy > /root/metricbeat-haproxy-enabled":
  cmd.run:
    - creates: "/root/metricbeat-haproxy-enabled"
    - requires:
        - pkg: beats
{% endif %}
