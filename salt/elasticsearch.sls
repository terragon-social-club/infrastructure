extend:
  salt_minion:
    service.running:
      - watch:
        - file: /usr/local/etc/salt/minion.d/mine.conf

/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine/elasticsearch.jinja.conf
    - template: jinja

include:
  - java

elasticsearch6:
  pkg.installed

elasticsearch:
  service.running:
    - enable: True
    - watch:
        - file: /usr/local/etc/elasticsearch/elasticsearch.yml

/usr/local/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt:///files/elasticsearch/elasticsearch.jinja.yml
    - template: jinja
    - require:
      - pkg: elasticsearch6
