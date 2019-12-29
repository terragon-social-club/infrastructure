extend:
  salt_minion:
    service.running:
      - watch:
        - file: /usr/local/etc/salt/minion.d/mine.conf
  /etc/rc.conf:
    file.append:
      - text:
        - logstash_mode="standalone"
        - logstash_log="YES"

/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine/logstash.jinja.conf
    - template: jinja

include:
  - java

logstash6:
  pkg.installed

logstash:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/logstash/logstash.yml
      - file: /usr/local/etc/logstash/logstash.conf

/usr/local/etc/logstash/logstash.yml:
  file.managed:
    - source: salt:///files/logstash/logstash.jinja.yml
    - template: jinja

/usr/local/etc/logstash/logstash.conf:
  file.managed:
    - source: salt:///files/logstash/logstash.jinja.conf
    - template: jinja
