base:
  '*':
    - eastern_standard_time
    - security
    - minion
    - fail2ban
    - fastboot

  'saltm':
    - master

  'roles:logstash':
    - match: grain
    - logstash

  'roles:elasticsearch':
    - match: grain
    - elasticsearch

  'roles:couchdb':
    - match: grain
    - couchdb

  'nodejs-api*':
    - nodejs_api

  'haproxy-couchdb*':
    - letsencrypt
    - haproxy.couchdb

  'haproxy-nodejsapi*':
    - letsencrypt
    - haproxy.pm2
