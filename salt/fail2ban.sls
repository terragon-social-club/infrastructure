include:
  - ipfw

py36-fail2ban:
  pkg.installed

/usr/local/etc/fail2ban/jail.d/jail-ssh.conf:
  file.managed:
    - source: salt:///files/fail2ban/jail-ssh.jinja.conf
    - template: jinja
    - require:
      - pkg: py36-fail2ban

fail2ban:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/fail2ban/jail.d/jail-ssh.conf
