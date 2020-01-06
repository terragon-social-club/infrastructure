firewall_type:
  sysrc.managed:
    - value: "client"

ipfw:
  service.running:
    - enable: True
