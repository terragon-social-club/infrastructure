salt_minion:
  service.running:
    - enable: True
    
/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine/mine.jinja.conf
    - template: jinja
