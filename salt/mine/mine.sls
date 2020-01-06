mine_functions:
  ip_list:
    - mine_function: network.interface_ip
    - vtnet1

/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine.jinja.conf
    - template: jinja
