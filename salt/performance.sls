"limit descriptors 65536 && touch /root/.maxfiles-tuned":
  cmd.run:
    - creates: /root/.maxfiles-tuned

/etc/login.conf:
  file.managed:
    - source: salt:///files/freebsd/login.jinja.conf
    - template: jinja

kern.maxfiles:
  sysctl.present:
    - value: 65536
