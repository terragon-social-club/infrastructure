beats:
  pkg.installed

/usr/local/etc/filebeat.yml:
  file.managed:
    - source: salt:///files/filebeat/filebeat.jinja.yml
    - template: jinja
    - require:
      - pkg: beats
    - default:
      - log_files:
        - /var/log/salt/minion
        - /var/log/salt/master
        - /var/log/auth

filebeat:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/filebeat.yml
