libnghttp2:
  pkg.installed:
    - refresh_db: True

pkg install -y libnghttp2:
  cmd.run:
    - unless: npm version

www/npm:
  pkg.installed:
    - require:
      - cmd: pkg install -y libnghttp2

"@terragon/api@1.7.3":
  npm.installed:
    - require:
      - pkg: www/npm

pm2:
  npm.installed:
    - require:
      - pkg: www/npm

pm2 startup --hp /:
  cmd.run:
    - runas: root
    - creates: /usr/local/etc/rc.d/pm2_root
    - env:
      - PM2_API_IPADDR: {{ salt['network.interface_ip']('vtnet1') }}
    - require:
      - cmd: pm2 start /usr/local/etc/process.yml --hp /

pm2 start /usr/local/etc/process.yml --hp /:
  cmd.run:
    - env:
      - PM2_API_IPADDR: {{ salt['network.interface_ip']('vtnet1') }}
    - unless: pm2 describe terragon --hp /
    - require:
      - npm: pm2
      - npm: "@terragon/api@1.7.3"
      - file: /usr/local/etc/process.yml

pm2_root:
  service.running:
    - enable: True
    - require:
      - cmd: pm2 startup --hp /

/usr/local/etc/process.yml:
  file.managed:
    - source: salt:///files/nodejs_api/pm2.process.yml
    - template: jinja
