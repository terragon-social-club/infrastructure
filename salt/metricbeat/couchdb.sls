extend:
  /usr/local/etc/metricbeat.yml:
    file.managed:
      - source: salt:///files/metricbeat/couchdb.jinja.yml
