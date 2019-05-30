apache24:
  pkg.installed

service.running:
  - enable: True
  - reload: True
  - watch:
      - file: /usr/local/etc/apache24/httpd.conf
      
