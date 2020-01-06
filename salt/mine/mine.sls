mine_functions:
  internal_ip_addrs:
    mine_function: network.ip_addrs
    interface: vtnet1

/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine.jinja.conf
    - template: jinja
