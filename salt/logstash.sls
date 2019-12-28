include:
  - java

logstash6:
  pkg.installed

extend:
  /etc/rc.conf:
    file.append:
      - text:
        - logstash_mode="standalone"
        - logstash_log="YES"

logstash:
  service.running:
    - enable: True
    - watch:
      - file: /etc/rc.conf
