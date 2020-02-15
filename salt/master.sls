extend:
  /usr/local/etc/filebeat.yml:
    file.managed:
      - context:
        specific_log_files:
          - /var/log/salt/master
          - /var/log/salt/key

/root/.ssh/id_rsa.pub:
  file.managed:
    - mode: 644
    - replace: False

/root/.ssh/id_rsa:
  file.managed:
    - mode: 600
    - replace: False

salt_master:
  service.running:
    - enable: True
