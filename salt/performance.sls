"limit descriptors 200000 && touch /root/.maxfiles-tuned":
  cmd.run:
    - creates: /root/.maxfiles-tuned

/etc/sysctl.conf:
  file.append:
    - require:
      - cmd: "limit descriptors 200000 && touch /root/.maxfiles-tuned"
    - text:
      - limit descriptors 200000
