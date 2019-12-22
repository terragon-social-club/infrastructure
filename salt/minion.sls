salt_minion:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/salt/minion.d/mines.conf

/usr/local/etc/salt/minion.d/mines.conf:
  file.managed:
    - source: salt:///files/salt/mines.jinja.conf
    - template: jinja
