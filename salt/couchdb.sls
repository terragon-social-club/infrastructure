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
      - file: /usr/local/etc/couchdb2/local.d/custom.ini
      - file: /usr/local/etc/couchdb2/vm.args
      - file: /usr/local/etc/rc.d/couchdb2

/usr/local/etc/couchdb2/local.d:
  file.directory:
    - user: couchdb
    - group: couchdb
    - require:
      - pkg: couchdb2
        
/usr/local/etc/couchdb2/local.d/custom.ini:
  file.managed:
    - source: salt:///files/couchdb/local.jinja.ini
    - user: couchdb
    - group: couchdb
    - require:
      - pkg: couchdb2
      - file: /usr/local/etc/couchdb2/local.d

/usr/local/etc/couchdb2/vm.args:
  file.managed:
    - source: salt:///files/couchdb/vm.jinja.args
    - require:
      - pkg: couchdb2

/usr/local/etc/rc.d/couchdb2:
  file.managed:
    - source: salt:///files/couchdb/rc.conf
    - require:
      - pkg: couchdb2
      - file: /usr/local/etc/couchdb2/local.d/custom.ini

/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/http.couchdb.jinja.conf
    - template: jinja
    - require:
      - pkg: apache24
