base:
  '*':
    - eastern_standard_time
    - security

  'master':
    - master

  'couchdb*':
    - letsencrypt
    - apache
    - couchdb

  'nodejs-api*':
    - letsencrypt
    - apache
    - nodejs_api
