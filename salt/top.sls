base:
  '*':
    - eastern_standard_time
    - security

  'saltm':
    - master

  'couchdb*':
    - couchdb

  'haproxy*':
    - haproxy

  'nodejs-api*':
    - letsencrypt
    - apache
    - nodejs_api
