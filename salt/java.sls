/etc/fstab:
  file.append:
    - text:
      - fdesc /dev/fd fdescfs rw  0 0
      - proc   /proc  procfs  rw  0 0
