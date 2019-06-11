www/npm:
  pkg.installed: []

pm2:
  npm.installed:
    - require:
      - pkg: www/npm

pm2 startup:
  cmd.run:
    - runas: root
    - creates: /usr/local/etc/rc.d/pm2_root
    - require:
      - npm: pm2

pm2_root:
  service.running:
    - enable: True
    - require:
      - cmd: pm2 startup

"@terragon/api@latest":
  npm.installed:
    - require:
      - service: pm2_root
