salt_minion:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/salt/minion.d/mine.conf

/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine.jinja.conf
    - template: jinja
