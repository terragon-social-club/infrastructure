base:
  '*':
    - eastern_standard_time
    - security

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