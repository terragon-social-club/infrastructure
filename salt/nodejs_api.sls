include:
  - apache

extend:
  apache24:
    service.running:
      - watch:
        - file: /usr/local/etc/apache24/httpd.conf

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
      - npm: "@terragon/api"
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

/usr/local/etc/apache24/httpd.conf:
  file.managed:
    - source: salt:///files/apache/http.pm2.jinja.conf
    - template: jinja
    - require:
      - pkg: apache24
