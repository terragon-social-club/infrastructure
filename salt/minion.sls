salt_minion:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/salt/minion.d/mine.conf
