base:
  '*':
    - security
    - fastboot
    - eastern_standard_time
    - fail2ban

  'saltm':
    - master

  'couchdb*':
    - couchdb

  'nodejs-api*':
    - nodejs_api

  'haproxy-couchdb*':
    - letsencrypt
    - haproxy.couchdb

  'haproxy-nodejsapi*':
    - letsencrypt
    - haproxy.pm2