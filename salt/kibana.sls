kibana:
  pkg.installed:
    - name: kibana6
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/kibana/kibana.yml

/usr/local/etc/kibana/kibana.yml:
  file.managed:
    - source: salt:///files/kibana/kibana.jinja.yml
    - template: jinja
