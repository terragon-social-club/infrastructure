firewall_type:
  sysrc.managed:
    - value: "workstation"

firewall_myservices:
  sysrc.managed:
    - value: "22"

firewall_logging:
  sysrc.managed:
    - value: "YES"

ipfw:
  service.running:
    - enable: True
