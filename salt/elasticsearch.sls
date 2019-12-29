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
