libnghttp2:
  pkg.installed:
    - refresh_db: True

pkg install -y libnghttp2:
  cmd.run:
    - unless: npm
  
www/npm:
  pkg.installed:
    - require:
      - cmd: pkg install -y libnghttp2

"@terragon/api@1.5.22":
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
      - npm: "@terragon/api@1.5.22"
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
