www/npm:
  pkg.installed: []

pm2:
  npm.installed:
    - require:
      - pkg: www/npm

pm2 startup:
  cmd.run:
    - creates: /usr/local/etc/rc.d/pm2_root
    - require:
      - npm: mp2

pm2_root:
  service.running:
    - enable: True
    - require:
      - cmd: pm2 startup

