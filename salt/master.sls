/root/.ssh/id_rsa.pub:
  file.managed:
    - mode: 644

/root/.ssh/id_rsa:
  file.managed:
    - mode: 600
