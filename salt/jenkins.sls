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
        
/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/http.jenkins.conf
    - require:
      - pkg: apache24
