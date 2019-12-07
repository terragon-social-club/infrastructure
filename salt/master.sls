/root/.ssh/id_rsa.pub:
  file.managed:
    - mode: 644

/root/.ssh/id_rsa:
  file.managed:
    - mode: 600

couchdb_username:
  environ.setenv:
    - value: {{ salt['grains.get_or_set_hash']('couchdb:username') }}

couchdb_password:
  environ.setenv:
    - value: {{ salt['grains.get_or_set_hash']('couchdb:password') }}
    