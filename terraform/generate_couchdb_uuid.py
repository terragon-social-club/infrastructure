import sys, json, os
from subprocess import Popen, PIPE, STDOUT
data = json.load(sys.stdin)
data['uuids'] = ["dedd"]

command = "ssh -i /dev/stdin root@" + data['master_public_ip'] + " \"ssh " + data['couch_private_ip'] + " curl -s 'http://" + data['couch_private_ip'] + ":5984/_uuids/\?count=1'\""

p = Popen([command], shell=True, stdout=PIPE, stdin=PIPE, stderr=PIPE)
stdout_data = p.communicate(input=data['private_key'])[0]

print json.dumps(json.loads('{"uuids": "'+stdout_data+'}"'))
