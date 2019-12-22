couchdb2:
  pkg.installed: []
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/etc/couchdb2/local.d/custom.ini
      - file: /usr/local/etc/couchdb2/vm.args
      - file: /usr/local/etc/rc.d/couchdb2

/usr/local/etc/couchdb2/local.d:
  file.directory:
    - user: couchdb
    - group: couchdb
    - require:
      - pkg: couchdb2
        
/usr/local/etc/couchdb2/local.d/custom.ini:
  file.managed:
    - source: salt:///files/couchdb/local.jinja.ini
    - template: jinja
    - user: couchdb
    - group: couchdb
    - require:
      - pkg: couchdb2
      - file: /usr/local/etc/couchdb2/local.d

/usr/local/etc/couchdb2/vm.args:
  file.managed:
    - source: salt:///files/couchdb/vm.jinja.args
    - template: jinja
    - require:
      - pkg: couchdb2

/usr/local/etc/rc.d/couchdb2:
  file.managed:
    - source: salt:///files/couchdb/rc.conf
    - require:
      - pkg: couchdb2
      - file: /usr/local/etc/couchdb2/local.d/custom.ini

mine_functions:
  couchdb_uuid:
    - mine_function: cmd.run 
    - curl -s http://{{ salt['network.interface_ip']('vtnet1') }}:5984/_uuids?count=1
