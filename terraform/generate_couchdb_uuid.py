import sys, json, os, subprocess
data = json.load(sys.stdin)

d = json.loads(subprocess.run(['ssh', '-i /dev/stdin', "root@" + data['master_public_ip'] + " \"ssh -o StrictHostKeyChecking=no " + data['couch_private_ip'] + " curl -s 'http://" + data['couch_private_ip'] + ":5984/_uuids/\?count=1'\""], check=True, input=data['private_key'], shell=True))
print("{\"uuid\": \"" + d['uuids'][0] + "\"}")
