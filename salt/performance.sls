"limit descriptors 65536 && touch /root/.maxfiles-tuned":
  cmd.run:
    - creates: /root/.maxfiles-tuned

/etc/login.conf:
  file.managed:
    - source: salt:///files/freebsd/login.jinja.conf
    - template: jinja

extend:
  /boot/loader.conf:
    file.append:
      - require:
        - cmd: "limit descriptors 1048576 && touch /root/.maxfiles-tuned"
      - text:
        - sysctl kern.maxfilesperproc=65536
        - sysctl kern.maxfiles=65536
