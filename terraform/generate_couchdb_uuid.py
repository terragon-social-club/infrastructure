import sys, json, os, subprocess
data = json.load(sys.stdin)

d = json.loads(subprocess.check_output(['ssh', '-i /dev/stdin', "root@" + data['master_public_ip'] + " \"ssh -o StrictHostKeyChecking=no " + data['couch_private_ip'] + " curl -s 'http://" + data['couch_private_ip'] + ":5984/_uuids/\?count=1'\""], input=data['private_key']))
print("{\"uuid\": \"" + d['uuids'][0] + "\"}")
