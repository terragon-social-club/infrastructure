haproxy:
  pkg.installed: []
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /usr/local/etc/haproxy.conf
      