{% set has_lp_running = salt['mine.get']('roles:logstash', 'private_ip', tgt_type='grain').items()|length > 0 %}
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
        - /var/log/auth.log
        - /var/log/salt/minion
        - /var/log/fail2ban.log
        - /var/log/userlog
      general_log_files: []
      specific_log_files: []

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
