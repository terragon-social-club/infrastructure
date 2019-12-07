www/npm:
  pkg.installed: []

libnghttp2:
  pkg.installed: []

pm2:
  npm.installed:
    - require:
      - pkg: www/npm
      - pkg: libnghttp2

pm2 startup:
  cmd.run:
    - runas: root
    - creates: /usr/local/etc/rc.d/pm2_root
    - env:
      - PM2_API_IPADDR: {{ grains['private_ip_address'] }}
    - require:
      - cmd: pm2 start /usr/local/etc/process.yml

pm2 start /usr/local/etc/process.yml:
  cmd.run:
    - env:
      - PM2_API_IPADDR: {{ grains['private_ip_address'] }}
    - unless: pm2 describe terragon
    - require:
      - npm: pm2
        
pm2_root:
  service.running:
    - enable: True
    - watch:
      - npm: "@terragon/api@1.5.13"
    - require:
      - cmd: pm2 startup

"@terragon/api@1.5.13":
  npm.installed:
    - require:
      - pkg: www/npm

/usr/local/etc/process.yml:
  file.managed:
    - source: salt:///files/nodejs_api/pm2.process.yml
    - template: jinja
