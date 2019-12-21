import sys, json;
data = json.load(sys.stdin)

command = "echo " + data['private_key'] + " | ssh -q -i /dev/stdin root@" + data['master_public_ip'] + "\"ssh " + data['couch_private_ip'] + "\" 'curl -s http://'" + data['couch_private_ip'] + ":5984\?count=1"

stream = os.popen(command)
output = stream.read()
output