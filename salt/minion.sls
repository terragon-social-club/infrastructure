/etc/ssh/sshd_config:
  file.managed:
    - source: salt:///files/unix/etc/ssh/sshd_config
    - user: root
