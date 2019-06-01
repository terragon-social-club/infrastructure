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

pkg.installed:
  - pkgs:
    - nodejs
    - git
        
/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/http.jenkins.jinja.conf
    - template: jinja
    - require:
      - pkg: apache24

/usr/local/etc/rc.d/jenkins:
  file.managed:
    - source: salt:///files/jenkins/rc.conf
    - require:
      - pkg: jenkins
