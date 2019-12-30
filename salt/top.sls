base:
  '*':
    - eastern_standard_time
    - minion
    - security
    - performance
    - fail2ban
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

  'roles:kibana':
    - match: grain
    - kibana

  'roles:haproxy-kibana':
    - match: grain
    - haproxy.kibana

  'roles:couchdb':
    - match: grain
    - couchdb

  'haproxy-couchdb*':
    - haproxy.couchdb

  'nodejs-api*':
    - nodejs_api

  'haproxy-nodejsapi*':
    - haproxy.pm2
