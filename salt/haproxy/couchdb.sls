extend:
  /usr/local/etc/haproxy.conf:
    file.managed:
      - source: salt:///files/haproxy/haproxy.couchdb.jinja
  /usr/local/etc/salt/minion.d/mine.conf:
    file.managed:
      - source: salt:///files/salt/mine.jinja.conf

