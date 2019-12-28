/usr/local/etc/ipfw.rules:
  file.managed:
    - source: salt:///files/ipfw/base.rules
    - template: jinja
