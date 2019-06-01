include:
  - apache

extend:
  apache24:
    service.running:
      - watch:
        - file: /usr/local/etc/apache24/httpd.conf
  
jenkins:
  pkg.installed: []
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/rc.d/jenkins
        
/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/http.jenkins.jinja.conf
    - require:
      - pkg: apache24

/usr/local/etc/rc.d/jenkins:
  file.managed:
    - template: jinja
    - source: salt:///files/jenkins/rc.conf
    - require:
      - pkg: jenkins
