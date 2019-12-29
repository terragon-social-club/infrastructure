"limit descriptors 1048576 && touch /root/.maxfiles-tuned":
  cmd.run:
    - creates: /root/.maxfiles-tuned

extend:
  /boot/loader.conf:
    file.append:
      - require:
        - cmd: "limit descriptors 1048576 && touch /root/.maxfiles-tuned"
      - text:
        - sysctl kern.maxfilesperproc=1048576
        - sysctl kern.maxvnodes=1048576
        - sysctl kern.maxfiles=1048576
