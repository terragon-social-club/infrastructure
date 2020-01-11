salt_minion:
  service.running:
    - enable: True

mine_functions:
  network.interface_ip:
    - vtnet1
