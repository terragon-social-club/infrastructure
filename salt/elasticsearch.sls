extend:
  /usr/local/etc/filebeat.yml:
    file.managed:
      - context:
        specific_log_files:
          - /var/log/elasticsearch/elasticsearch.log
          - /var/log/elasticsearch/elasticsearch_access.log
          - /var/log/elasticsearch/elasticsearch_audit.log
          - /var/log/elasticsearch/elasticsearch_index_search_slowlog.log
          - /var/log/elasticsearch/elasticsearch_index_indexing_slowlog.log

include:
  - java
  - portsnap

portsnap extract:
  cmd.run:
    - creates: /usr/ports/textproc/elasticsearch7
    - require:
      - cmd: portsnap_fetch

elasticsearch:
  ports.installed:
    - name: textproc/elasticsearch7
    - require:
      - cmd: portsnap extract
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/elasticsearch/elasticsearch.yml

/usr/local/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt:///files/elasticsearch/elasticsearch.jinja.yml
    - template: jinja
    - require:
      - ports: textproc/elasticsearch7
  
