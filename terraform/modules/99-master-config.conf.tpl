interface: ${private_ip}
fileserver_backend:
  - git

gitfs_remotes:
  - https://github.com/terragon-social-club/infrastructure.git:
    - mountpoint: salt:///
  - https://github.com/saltstack-formulas/elasticsearch-formula.git
      
gitfs_root: salt
transport: zeromq
file_recv: True
pillar_roots: /srv/pillar
