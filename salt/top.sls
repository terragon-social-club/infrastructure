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
