firewall_type:
  sysrc.managed:
    - value: "open"

ipfw:
  service.running:
    - enable: True
    - watch:
      - sysrc: firewall_type
