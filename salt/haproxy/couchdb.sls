extend:
  /usr/local/etc/haproxy.conf:
    file.managed:
      - source: salt:///files/haproxy/haproxy.couchdb.jinja
