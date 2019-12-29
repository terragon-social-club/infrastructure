kibana6:
  pkg.installed

/usr/local/etc/kibana/kibana.yml:
  file.managed:
    - source: salt:///files/kibana/kibana.jinja.yml
    - template: jinja

kibana:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/kibana/kibana.yml