kern.maxfiles:
  sysctl.present:
    - value: 65536
    - config: /etc/sysctl.conf

kern.maxproc:
  sysctl.present:
    - value: 65536
    - config: /etc/sysctl.conf
