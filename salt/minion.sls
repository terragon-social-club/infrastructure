salt_minion:
  service.running:
    - enable: True

mine_functions:
  network.ip_addrs: [eth0]
