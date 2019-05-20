/etc/resolv.conf:
  file.managed:
    - source: salt:///files/unix/etc/resolv.conf
      
