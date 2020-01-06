extend:
  salt_minion:
    service.running:
      - watch:
        - file: /usr/local/etc/salt/minion.d/mine.conf
  /usr/local/etc/filebeat.yml:
    file.managed:
      - context:
        specific_log_files:
          - /var/log/logstash/logstash-plain.log

include:
  - java

logstash:
  pkg.installed:
    - name: logstash6
  service.running:
    - enable: True
    - require:
      - file: /usr/local/etc/logstash/logstash.yml
      - file: /usr/local/etc/logstash/logstash.conf
    - watch:
      - file: /usr/local/etc/logstash/logstash.yml
      - file: /usr/local/etc/logstash/logstash.conf
      - sysrc: logstash_mode
      - sysrc: logstash_log

logstash_mode:
  sysrc.managed:
    - value: "standalone"

logstash_log:
  sysrc.managed:
    - value: "YES"
    
/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine/logstash.jinja.conf
    - template: jinja

/usr/local/etc/logstash/logstash.yml:
  file.managed:
    - source: salt:///files/logstash/logstash.jinja.yml
    - template: jinja

/usr/local/etc/logstash/logstash.conf:
  file.managed:
    - source: salt:///files/logstash/logstash.jinja.conf
    - template: jinja

/usr/local/logstash/bin/logstash-plugin install --version 5.1.9 logstash-input-beats:
  cmd.run:
    - creates: /usr/local/logstash/vendor/bundle/jruby/2.3.0/gems/logstash-input-beats-5.1.9-java/Gemfile
