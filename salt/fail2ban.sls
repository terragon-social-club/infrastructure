fail2ban:
  pkg.installed:
    - name: py37-fail2ban
  service.running:
    - require:
      - file: /usr/local/etc/fail2ban/jail.d/jail-ssh.conf
    - enable: True
    - watch:
      - file: /usr/local/etc/fail2ban/jail.d/jail-ssh.conf

/usr/local/etc/fail2ban/jail.d/jail-ssh.conf:
  file.managed:
    - source: salt:///files/fail2ban/jail-ssh.jinja.conf
    - template: jinja
    - require:
      - pkg: py36-fail2ban
