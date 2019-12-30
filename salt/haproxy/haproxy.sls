haproxy:
  pkg.installed: []
  service.running:
    - enable: True

/usr/local/etc/haproxy.conf:
  file.managed:
    - source: salt:///files/haproxy/haproxy.default.jinja
    - template: jinja
    - require:
      - pkg: haproxy
