extend:
  salt_minion:
    service.running:
      - watch:
        - file: /usr/local/etc/salt/minion.d/mine.conf
  /usr/local/etc/filebeat.yml:
    file.managed:
      - context:
        specific_log_files:
          - /var/log/couchdb2/couch.log

/usr/local/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt:///files/salt/mine/couchdb.jinja.conf
    - template: jinja

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

{% if grains['id'] == 'couchdb-a' %}
"curl -X PUT -H \"Content-Type: application/json\" 'http://{{ grains['couch_user'] }}:{{ grains['couch_pass'] }}@{{ salt['network.interface_ip']('vtnet1') }}:5984/_users' -d '' > '/root/created-users-database'":
  cmd.run:
      - creates: /root/created-users-database
      - hide_output: True
      - output_loglevel: quiet
      - require:
        - service: couchdb2

"curl -X PUT -H \"Content-Type: application/json\" 'http://{{ grains['couch_user'] }}:{{ grains['couch_pass'] }}@{{ salt['network.interface_ip']('vtnet1') }}:5984/_global_changes' -d '' > '/root/created-global-changes-database'":
  cmd.run:
      - creates: /root/created-global-changes-database
      - hide_output: True
      - output_loglevel: quiet
      - require:
        - service: couchdb2

"curl -X PUT -H \"Content-Type: application/json\" 'http://{{ grains['couch_user'] }}:{{ grains['couch_pass'] }}@{{ salt['network.interface_ip']('vtnet1') }}:5984/_replicator' -d '' > '/root/created-replicator-database'":
  cmd.run:
      - creates: /root/created-replicator-database
      - hide_output: True
      - output_loglevel: quiet
      - require:
        - service: couchdb2

"curl -X PUT -H \"Content-Type: application/json\" 'http://{{ grains['couch_user'] }}:{{ grains['couch_pass'] }}@{{ salt['network.interface_ip']('vtnet1') }}:5984/test1' -d '' > '/root/created-replicator-database'":
  cmd.run:
      - creates: /root/created-replicator-database
      - hide_output: True
      - output_loglevel: quiet
      - require:
        - service: couchdb2
{% endif %}