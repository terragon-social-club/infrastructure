include:
  - apache

jenkins:
  pkg.installed: []
  service.running:
    - enable: True
   
extend:
  apache24:
    service.running:
      - watch:
        - file: /usr/local/etc/apache24/httpd.conf

enable modules:
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
