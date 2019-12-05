haproxy:
  pkg.installed: []
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /usr/local/etc/haproxy.conf

/usr/local/etc/haproxy.conf:
  file.managed:
    - source: salt:///files/haproxy/haproxy.couchdb.jinja
    - require:
      - pkg: haproxy