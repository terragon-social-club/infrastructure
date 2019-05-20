github.com:
  ssh_known_hosts:
    - present

/root/.ssh/config:
  file.managed:
    - source: salt:///files/unix/root/.ssh/config
    - user: root
