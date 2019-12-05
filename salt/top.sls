base:
  '*':
    - eastern_standard_time
    - security

  'saltm':
    - master

  'couchdb*':
    - letsencrypt
    - apache
    - couchdb

  'nodejs-api*':
    - letsencrypt
    - apache
    - nodejs_api
