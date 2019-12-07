base:
  '*':
    - couchdb_username: {{ salt['random.get_str'](20) }}
    - couchdb_password: {{ salt['random.get_str'](20) }}