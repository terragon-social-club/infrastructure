/srv/terragon.us:
  file.recurse:
    - source: salt://butter/*
    - user: freebsd
    - clean: True

npm:
  pkg.installed

/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt://files/apache/httpd.react.conf
    - require:
      - pkg: apache24
        
apache24:
  pkg.installed: []
  service.running:
    - enable: True
    - require: 
      - file: /usr/local/etc/apache24/httpd.conf
    - watch:
      - file: /usr/local/etc/apache24/httpd.conf
