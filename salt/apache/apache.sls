apache24:
  pkg.installed: []
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /usr/local/etc/apache24/httpd.conf

/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/httpd.default.jinja
    - template: jinja
    - require:
      - pkg: apache24
