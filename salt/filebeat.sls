{% set has_lp_running = salt['mine.get']('roles:elasticsearch', 'network.interface_ip', tgt_type='grain').items()|length > 0 %}
beats:
  pkg.installed

/usr/local/etc/filebeat.yml:
  file.managed:
    - source: salt:///files/filebeat/filebeat.jinja.yml
    - template: jinja
    - require:
      - pkg: beats
    - defaults:
      log_files:
        - /var/log/auth

filebeat:
{% if has_lp_running %}
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/filebeat.yml
{% else %}
  service.dead:
    - enable: False
{% endif %}