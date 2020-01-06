firewall_type:
  sysrc.managed:
    - value: "client"

ipfw:
  service.running:
    - enable: True
    - watch:
      - sysrc: firewall_type
