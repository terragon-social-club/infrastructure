{% set pil = pillar['/usr/local/etc/filebeat.yml'] %}

extend:
  /usr/local/etc/haproxy.conf:
    file.managed:
      - source: salt:///files/haproxy/haproxy.couchdb.jinja
  /usr/local/etc/filebeat.yml:
    file.managed:
      - context: