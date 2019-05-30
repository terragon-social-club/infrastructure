jenkins:
  pkg.installed: []
  service.running:
    - enable: True

apache24:
  service.running:
    - watch:
      - file: /usr/local/etc/apache24/httpd.conf

apache_module.enabled:
  - names:
    - proxy
    - proxy_http
    - headers
        
/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/http.jenkins.conf
    - require:
      - pkg: apache24
