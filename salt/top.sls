base:
  '*':
    - security
    - fastboot
    - eastern_standard_time
    - fail2ban
    - minion

  'saltm':
    - master

  'couchdb*':
    - couchdb.base

  'nodejs-api*':
    - nodejs_api

  'haproxy-couchdb*':
    - letsencrypt
    - haproxy.couchdb

  'haproxy-nodejsapi*':
    - letsencrypt
    - haproxy.pm2
