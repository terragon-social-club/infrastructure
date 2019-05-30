jenkins:
  pkg.installed
  service.running:
    - enable: True
    - require:
        - file: /usr/local/etc/rc.d/jenkins
        - file: /home/jenkins/.ssh/id_rsa
        - file: /home/jenkins/.ssh/id_rsa.pub
    - watch:
        - file: /usr/local/etc/rc.d/jenkins
