firewall_type:
  sysrc.managed:
    - value: "/etc/ipfw.rules"

ipfw:
  service.running:
    - enable: True
    - watch:
      - sysrc: firewall_type
      - file: /etc/ipfw.rules

/etc/ipfw.rules:
  file.managed:
    - source: salt:///files/ipfw/ipfw.jinja.rules
    - template: jinja
