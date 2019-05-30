jenkins:
  pkg.installed
  service.running:
    - enable: True
    - watch:
        - file: /usr/local/etc/rc.d/jenkins
