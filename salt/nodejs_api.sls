"libnghttp2":
  pkg.installed:
    - refresh_db: True

www/npm:
  pkg.installed:
    - require:
      - pkg: "libnghttp2"

"@terragon/api@1.5.15":
  npm.installed:
    - require:
      - pkg: www/npm

pm2:
  npm.installed:
    - require:
      - pkg: www/npm
      
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
      - npm: "@terragon/api@1.5.15"
      - file: /usr/local/etc/process.yml
        
pm2_root:
  service.running:
    - enable: True
    - require:
      - cmd: pm2 startup

/usr/local/etc/process.yml:
  file.managed:
    - source: salt:///files/nodejs_api/pm2.process.yml
    - template: jinja
