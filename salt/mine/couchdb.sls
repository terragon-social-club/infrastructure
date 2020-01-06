extend:
  mine_functions:
    uuid:
      mine_function: cmd.run
      cmd: "curl -s \"http://{{ salt['network.interface_ip']('vtnet1') }}:5984/\" | jq .uuid  | sed 's/\"//g'"
      python_shell: True
