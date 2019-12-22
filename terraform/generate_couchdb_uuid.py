import sys, json, os
from subprocess import Popen, PIPE, STDOUT
data = json.load(sys.stdin)

p = Popen(['ssh', '-i /dev/stdin', "root@" + data['master_public_ip'] + " \"ssh -o StrictHostKeyChecking=no " + data['couch_private_ip'] + " curl -s 'http://" + data['couch_private_ip'] + ":5984/_uuids/\?count=1'\""], stdout=PIPE, stdin=PIPE, stderr=STDOUT) 
grep_stdout = p.communicate(input=data['private_key'])[0]

#d = json.loads(grep_stdout.decode())
print("{\"uuid\": \"" + grep_stdout.replace('\n', '') + "\"}")
