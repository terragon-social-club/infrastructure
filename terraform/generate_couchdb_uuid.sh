#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Extract "foo" and "baz" arguments from the input into
# FOO and BAZ shell variables.
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "MASTER_PUBLIC_IP=\(.master_public_ip) PRIVATE_KEY=\(.private_key) COUCH_PRIVATE_IP=\(.couch_private_ip)"')"

"$(echo '$PRIVATE_KEY' | ssh -q -i /dev/stdin root@$MASTER_PUBLIC_IP "ssh $COUCH_PRIVATE_IP \"curl -s http://$COUCH_PRIVATE_IP:5984/_uuids\?count=1\"")"