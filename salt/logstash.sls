extend:
  /usr/local/etc/filebeat.yml:
    file.managed:
      - context:
        specific_log_files:
          - /var/log/logstash/logstash-plain.log

include:
  - java
  - geoipupdate

logstash:
  pkg.installed:
    - name: logstash7
    - require:
      - cmd: mount -a > /root/initial-java-mount
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/logstash/logstash.yml
      - file: /usr/local/etc/logstash/logstash.conf

logstash_mode:
  sysrc.managed:
    - value: "agent"

logstash_log:
  sysrc.managed:
    - value: "YES"

/usr/local/etc/logstash/logstash.yml:
  file.managed:
    - source: salt:///files/logstash/logstash.jinja.yml
    - template: jinja

/usr/local/etc/logstash/logstash.conf:
  file.managed:
    - source: salt:///files/logstash/logstash.jinja.conf
    - template: jinja

/usr/local/logstash/bin/logstash-plugin install logstash-input-beats > /root/installed_logstash_plugin:
  cmd.run:
    - creates: /root/installed_logstash_plugin
    - require:
      - pkg: logstash
