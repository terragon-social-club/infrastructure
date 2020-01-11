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

/root/.ssh/id_rsa:
  file.managed:
    - mode: 600

salt_master:
  service.running:
    - enable: True
    - watch:
      - file: /root/pillar/top.sls
      - file: /root/pillar/data.sls

/root/pillar/top.sls:
  file.managed:
    - makedirs: True
    - source: salt:///pillar/top.sls

/root/pillar/data.sls:
  file.managed:
    - makedirs: True
    - source: salt:///pillar/data.sls
