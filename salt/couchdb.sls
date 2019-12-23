{% set couch_node_count = salt['mine.get']('roles:couchdb', 'network.interface_ip', tgt_type='grain').items()|length %}

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

curl -s -X POST -H "Content-Type: application/json" http://{{ grains['couch_user'] }}:{{ grains['couch_pass'] }}@{{ salt['network.interface_ip']('vtnet1') }}:5984/_cluster_setup -d '{"action":"enable_cluster", "bind_address":"{{ salt['network.interface_ip']('vtnet1') }}", "username":"{{ grains['couch_user'] }}", "password":"{{ grains['couch_pass'] }}", "node_count":"{{ couch_node_count }}"}' > /root/clustered:
  cmd.run:
    - creates: "/root/clustered"
    - require:
      - service: couchdb2
