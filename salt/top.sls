base:
  '*':
    - eastern_standard_time

  'jenkins':
    - letsencrypt
    - apache
    - jenkins

  'couchdb*':
    - letsencrypt
    - apache
    - couchdb

  'nodejs-api*':
    - nodejs_api
    
  'web-redirect':
    - letsencrypt
    - apache
    - redirect
