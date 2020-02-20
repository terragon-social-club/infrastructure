extend:
  /usr/local/etc/filebeat.yml:
    file.managed:
      - context:
        specific_log_files:
          - /.pm2/logs/terragon-error-0.log
          - /.pm2/logs/terragon-out-0.log

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

"@terragon/pipeline@0.0.2":
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
      - cmd: pm2 start --hp / /usr/local/etc/process.yml

pm2 start --hp / /usr/local/etc/process.yml:
  cmd.run:
    - env:
      - PM2_API_IPADDR: {{ salt['network.interface_ip']('vtnet1') }}
    - unless: pm2 describe --hp / terragon
    - require:
      - npm: pm2
      - npm: "@terragon/pipeline@0.0.2"
      - file: /usr/local/etc/process.yml

pm2_root:
  service.running:
    - enable: True
    - require:
      - cmd: pm2 startup --hp /

/usr/local/etc/process.yml:
  file.managed:
    - source: salt:///files/nodejs_api/pm3.process.yml
    - template: jinja
