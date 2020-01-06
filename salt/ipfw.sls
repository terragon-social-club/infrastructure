firewall_type:
  sysrc.managed:
    - value: "UNKNOWN"

ipfw:
  service.running:
    - enable: True
