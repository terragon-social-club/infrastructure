sysctl kern.maxfiles=65536 && touch /root/.maxfiles-tuned:
  cmd.run:
    - creates: /root/.maxfiles-tuned

/etc/sysctl.conf:
  file.append:
    - require:
      - cmd: sysctl kern.maxfiles=65536 && touch /root/.maxfiles-tuned
    - text:
      - sysctl kern.maxfiles=65536
