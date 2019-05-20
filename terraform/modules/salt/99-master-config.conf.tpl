interface: ${private_ip}
fileserver_backend:
  - git
  - minion
  
gitfs_remotes:
  - ssh://github.com/terragon-social-club/infrastructure.git:
      - mountpoint: salt:///
      
gitfs_root: salt
transport: tcp
file_recv: True

reactor:
  - jenkins/build/succeeded:
    - salt:///files/reactor/jenkins/post-build.sls
