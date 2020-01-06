base:
  '*':
    - eastern_standard_time
    - minion
    - security
    - fastboot

  'saltm':
    - master

  'roles:haproxy':
    - match: grain
    - letsencrypt
    - haproxy.haproxy

  'roles:logstash':
    - match: grain
    - logstash

  'roles:elasticsearch':
    - match: grain
    - elasticsearch

  'G@roles:kibana and not G@haproxy':
    - match: compound
    - kibana

  'G@roles:haproxy and G@roles:kibana':
    - match: compound
    - haproxy.kibana

  'G@roles:couchdb and not G@roles:haproxy':
    - match: compound
    - couchdb

  'G@roles:couchdb and G@roles:haproxy':
    - match: compound
    - haproxy.couchdb

  'G@roles:pm2 and not G@roles:haproxy':
    - match: compound
    - nodejs_api

  'G@roles:pm2 and G@roles:haproxy':
    - match: compound
    - haproxy.pm2
