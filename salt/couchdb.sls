include:
  - apache

extend:
  apache24:
    service.running:
      - watch:
        - file: /usr/local/etc/apache24/httpd.conf

couchdb:
  pkg.installed: []
  service.running:
    - enable: True
