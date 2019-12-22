curl -s "http://10.136.82.97:5984/_uuids?count=1" | jq -r '.uuids[0]' > uuid:
  cmd.run:
    - creates: /root/uuid

