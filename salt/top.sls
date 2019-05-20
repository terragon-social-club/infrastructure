base:
  #'*':
  #  - eastern_standard_time
  #  - networking
    
  #'roles:minion':
  #  - match: grain
  #  - minion
    
  #'roles:master':
  #  - match: grain
  #  - master
  #  - security
  #  - csh
    
  'roles:jenkins':
    - match: grain
    - git
    - node
    - jenkins
    - nginx
    - security
    
