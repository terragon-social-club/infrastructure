base:
  '*':
    - eastern_standard_time
    - security

  'saltm':
    - master

  'couchdb*':
    - couchdb

  'haproxy*':
    - letsencrypt
    - haproxy

  'nodejs-api*':
    - letsencrypt
    - haproxy
    - nodejs_api
