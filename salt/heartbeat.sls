heartbeat:
  service.running:
    - enable: True
    - watch:
      file: /usr/local/etc/heartbeat.yml

/usr/local/etc/heartbeat.yml:
  file.managed:
    - source: salt:///files/heartbeat/heartbeat.jinja.yml
    - template: jinja
