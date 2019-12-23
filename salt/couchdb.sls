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

# Warning the below exposes username and password in logs. Need to pass those in as env variables with cmd.run.env
{% if grains['id'] == 'couchdb-a' %}
{% set couchdb_nodes = salt['mine.get']('roles:couchdb', 'network.interface_ip', tgt_type='grain').items() %}
{% for couchdb_node_private_address in couchdb_nodes %}
{% if salt['network.interface_ip']('vtnet1') != couchdb_node_private_address[1] %}
"curl -s -X POST -H \"Content-Type: application/json\" http://{{ grains['couch_user'] }}:{{ grains['couch_pass'] }}@{{ salt['network.interface_ip']('vtnet1') }}:5984/_cluster_setup -d '{\"action\": \"add_node\", \"host\": \"{{ couchdb_node_private_address }}\", \"port\": 5984, \"username\": \"{{ grains['couch_user'] }}\", \"password\": \"{{ grains['couch_pass'] }}\"}' > '/root/clustered-{{ couchdb_node_private_address[0] }}'":
  cmd.run:
      - creates: /root/clustered-{{ couchdb_node_private_address[0] }}
      - hide_output: True
      - output_loglevel: quiet
      - require:
        - service: couchdb2
{% endif %}
{% endfor %}
{% endif %}