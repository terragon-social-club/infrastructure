include:
  - apache

jenkins:
  pkg.installed: []
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/rc.d/jenkins
   
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

/usr/local/etc/rc.d/jenkins:
  file.managed:
    - source: salt:///files/jenkins/rc.conf
    - template: jinja
    - defaults:
        fqdn: {{grains['fqdn']}}
    - require:
      - pkg: jenkins
