base:
  '*':
    - eastern_standard_time

  'jenkins':
    - letsencrypt
    - apache
    - jenkins

  'couchdb':
    - match: grain
    - letsencrypt
    - apache
    - couchdb

  'redirect':
    - match: grain
    - letsencrypt
    - redirect
