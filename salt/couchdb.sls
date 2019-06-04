include:
  - apache

extend:
  apache24:
    service.running:
      - watch:
        - file: /usr/local/etc/apache24/httpd.conf

couchdb2:
  pkg.installed: []
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/couchdb/local.ini

/usr/local/etc/couchdb2/local.ini:
  file.managed:
    - source: salt:///files/couchdb/local.ini
    - require:
      - pkg: couchdb2

/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/http.couchdb.jinja.conf
    - template: jinja
    - require:
      - pkg: apache24
