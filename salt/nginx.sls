nginx:
  pkg.installed: []
  service.running:
    - enable: True
    - require:
        - file: /usr/local/etc/nginx/nginx.conf
        - file: /usr/local/etc/nginx/cert.pem
        - file: /usr/local/etc/nginx/key.pem
    - watch:
        - file: /usr/local/etc/nginx/nginx.conf

/usr/local/etc/nginx/nginx.conf:
  file.managed:
    - source: salt:///files/freebsd-11.1/nginx-{{grains['roles'][0]}}.conf
    - require:
      - pkg: nginx

Generate Certificates:
  cmd.run:
    - name: "openssl req -x509 -newkey rsa:4096 -keyout /usr/local/etc/nginx/key.pem -out /usr/local/etc/nginx/cert.pem -days 365 -nodes -subj '/C=US/ST=Georgia/L=Atlanta/O=Mike Keen/OU=Org/CN={{ grains['fqdn'] }}'"
    - onlyif: 'test ! -e /usr/local/etc/nginx/cert.pem'
    - require:
      - pkg: nginx

/usr/local/etc/nginx/cert.pem:
  file.managed:
    - mode: 600
    - require:
      - cmd: Generate Certificates

/usr/local/etc/nginx/key.pem:
  file.managed:
    - mode: 600
    - require:
      - cmd: Generate Certificates
