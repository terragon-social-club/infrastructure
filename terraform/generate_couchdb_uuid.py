import sys, json, os, subprocess
from subprocess import Popen, PIPE, STDOUT
data = json.load(sys.stdin)
data['uuids'] = ["dedd"]

text_file = open("key", "w")
n = text_file.write(data['private_key'])
text_file.close()

subprocess.call(['chmod', '0600', 'key'])

command = "ssh -i key root@" + data['master_public_ip'] + " \"ssh " + data['couch_private_ip'] + " curl -s 'http://" + data['couch_private_ip'] + ":5984/_uuids/\?count=1'\""

p = Popen([command], shell=True, stdout=PIPE, stdin=PIPE, stderr=PIPE)
stdout_data = p.communicate(input=data['private_key'])[0]
d = json.loads(stdout_data)
print json.dumps(d['uuids'][0])
