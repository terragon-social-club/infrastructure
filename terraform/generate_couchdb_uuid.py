import sys, json, os, subprocess
data = json.load(sys.stdin)
data['uuids'] = ["dedd"]

text_file = open("/tmp/key", "w")
n = text_file.write(data['private_key'])
text_file.close()

subprocess.call(['chmod', '0600', '/tmp/key'])

d = json.loads(subprocess.check_output(['ssh', '-i key', "root@" + data['master_public_ip'] + " \"ssh -o StrictHostKeyChecking=no " + data['couch_private_ip'] + " curl -s 'http://" + data['couch_private_ip'] + ":5984/_uuids/\?count=1'\""]))
print("{\"uuid\": \"" + d['uuids'][0] + "\"}")
