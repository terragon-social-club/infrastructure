extend:
  /usr/local/etc/filebeat.yml:
    file.managed:
      - context:
        specific_log_files:
          - /var/db/beats/heartbeat/logs/heartbeat

heartbeat:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/heartbeat.yml

/usr/local/etc/heartbeat.yml:
  file.managed:
    - source: salt:///files/heartbeat/heartbeat.jinja.yml
    - template: jinja
