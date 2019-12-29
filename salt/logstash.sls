extend:
  salt_minion:
    service.running:
      - watch:
        - file: /usr/local/etc/salt/minion.d/mine.conf

/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine/logstash.jinja.conf
    - template: jinja

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
      - file: /usr/local/etc/logstash/logstash.yml
      - file: /usr/local/etc/logstash/logstash.conf

/usr/local/etc/logstash/logstash.yml:
  file.managed:
    - source: salt:///files/salt/logstash/logstash.jinja.yml
    - template: jinja

/usr/local/etc/logstash/logstash.conf:
  file.managed:
    - source: salt:///files/salt/logstash/logstash.jinja.conf
    - template: jinja