terraform:
  pkg.installed

gcc:
  pkg.installed
        
jenkins:
  pkg.installed:
    - name: jenkins-lts
  service.running:
    - enable: True
    - require:
        - file: /usr/local/etc/rc.d/jenkins
        - file: /home/jenkins/.ssh/id_rsa
        - file: /home/jenkins/.ssh/id_rsa.pub
    - watch:
        - file: /usr/local/etc/rc.d/jenkins

/usr/local/etc/rc.d/jenkins:
  file.managed:
    - source: salt:///files/freebsd-11.1/rc.d/jenkins
    - require:
      - pkg: jenkins-lts

/home/jenkins/.ssh/id_rsa:
  file.managed:
    - source: salt:///files/unix/id_rsa
    - makedirs: True
    - require:
      - pkg: jenkins-lts

/home/jenkins/.ssh/id_rsa.pub:
  file.managed:
    - source: salt:///files/unix/id_rsa.pub
    - makedirs: True
    - require:
      - pkg: jenkins-lts

/usr/local/etc/sudoers:
  file.blockreplace:
    - source: salt:///files/jenkins/sudoers.partial
    - show_changes: True
    - prepend_if_not_found: True
