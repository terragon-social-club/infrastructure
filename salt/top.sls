base:
  '*':
    - eastern_standard_time
    - security

  'jenkins*':
    - letsencrypt
    - apache
    - jenkins

  'couchdb*':
    - letsencrypt
    - apache
    - couchdb

  'nodejs-api*':
    - letsencrypt
    - apache
    - nodejs_api
    
  'web-redirect*':
    - letsencrypt
    - apache
    - redirect
