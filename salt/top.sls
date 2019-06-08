base:
  '*':
    - eastern_standard_time

  'jenkins':
    - letsencrypt
    - apache
    - jenkins

  'couchdb*':
    - match: grain
    - letsencrypt
    - apache
    - couchdb

  'web-redirect':
    - letsencrypt
    - apache
    - redirect
