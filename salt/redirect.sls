include:
  - apache

extend:
  apache24:
    service.running:
      - watch:
        - file: /usr/local/etc/apache24/httpd.conf

/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/http.redirect.jinja.conf
    - template: jinja
    - require:
      - pkg: apache24
