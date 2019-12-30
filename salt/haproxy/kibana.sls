extend:
  haproxy.haproxy:
    service.running:
      - watch:
        - file: /usr/local/etc/haproxy.conf
  /usr/local/etc/haproxy.conf:
    file.managed:
      - source: salt:///files/haproxy/haproxy.kibana.jinja
