www/npm:
  pkg.installed: []

pm2:
  npm.installed:
    - require:
      - pkg: www/npm

pm2 start /usr/local/etc/process.yml && pm2 startup:
  cmd.run:
    - runas: root
    - creates: /usr/local/etc/rc.d/pm2_root
    - require:
      - npm: pm2
      - file: /usr/local/etc/process.yml

pm2_root:
  service.running:
    - enable: True
    - watch:
      - npm: "@terragon/api"
    - require:
      - cmd: pm2 start /usr/local/etc/process.yml && pm2 startup

"@terragon/api":
  npm.installed:
    - force_reinstall: True
    - require:
      - pkg: www/npm

/usr/local/etc/process.yml:
  file.managed:
    - source: salt:///files/nodejs_api/pm2.process.yml
    - template: jinja
