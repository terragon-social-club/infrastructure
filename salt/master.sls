github.com:
  ssh_known_hosts:
    - present

/root/.ssh/config:
  file.managed:
    - source: salt:///files/unix/root/.ssh/config
    - user: root

/root/.ssh/id_rsa.pub:
  file.managed:
    - mode: 644

/root/.ssh/id_rsa:
  file.managed:
    - mode: 600
