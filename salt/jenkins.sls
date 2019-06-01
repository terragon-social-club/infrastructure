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

/usr/local/jenkins/.ssh:
  file.directory:
    - user: jenkins
    - require:
      - pkg: jenkins
        
ssh-keygen -t rsa -N \"\" -f /usr/local/jenkins/.ssh/id_rsa:
  cmd.run:
    - creates: /usr/local/jenkins/.ssh/id_rsa
    - require:
      - file: /usr/local/jenkins/.ssh
        
node:
  pkg.installed: []

npm:
  pkg.installed: []

git:
  pkg.installed: []
        
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
